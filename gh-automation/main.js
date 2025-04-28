/**
 * GitHub Repository Automation Script
 * 
 * Reads repository and team information from CSV files and creates them
 * in a GitHub Enterprise organization if they don't already exist.
 */

import fs from 'fs';
import path from 'path';
import { parse } from 'csv-parse/sync'; // Using sync for simplicity
import { Octokit } from '@octokit/rest';
import { throttling } from '@octokit/plugin-throttling';

// Get GitHub token from environment (provided by GitHub workflow)
const token = process.env.GITHUB_TOKEN;

if (!token) {
  console.error('Error: GITHUB_TOKEN environment variable not set');
  process.exit(1);
}

// Get organization name from environment
const organization = process.env.GITHUB_ORGANIZATION;
if (!organization) {
  console.error('Error: GITHUB_ORGANIZATION environment variable not set');
  process.exit(1);
}

// Initialize GitHub API client
const octokit = new Octokit({
  auth: token,
  baseUrl: process.env.GITHUB_API_URL,
  onRateLimit: (retryAfter, options, octokit, retryCount) => {
    octokit.log.warn(
      `Request quota exhausted for request ${options.method} ${options.url}`,
    );

    if (retryCount < 1) {
      // only retries once
      octokit.log.info(`Retrying after ${retryAfter} seconds!`);
      return true;
    }
  },
  onSecondaryRateLimit: (retryAfter, options, octokit) => {
    // does not retry, only logs a warning
    octokit.log.warn(
      `SecondaryRateLimit detected for request ${options.method} ${options.url}`,
    );
  }
});

async function createRepositories() {
  try {
    // Read and parse CSV file
    const csvFilePath = path.resolve('./csv/repos.csv');
    console.log(`Reading repository data from: ${csvFilePath}`);

    if (!fs.existsSync(csvFilePath)) {
      console.error(`Error: CSV file not found at ${csvFilePath}`);
      process.exit(1);
    }

    const csvContent = fs.readFileSync(csvFilePath, 'utf8');
    const repositories = parse(csvContent, { columns: true, skip_empty_lines: true });

    console.log(`Found ${repositories.length} repositories to process`);

    // Process each repository
    for (const repo of repositories) {
      const repoName = repo.name || repo.repository;

      if (!repoName) {
        console.warn('Warning: Repository name missing, skipping entry');
        continue;
      }

      try {
        // Check if repository already exists
        try {
          await octokit.repos.get({
            owner: organization,
            repo: repoName
          });
          console.log(`✓ Repository '${repoName}' already exists in ${organization}`);
          continue;
        } catch (error) {
          console.log("errors found", error.status);
          // Only proceed if the error is 404 (Not Found)
          if (error.status !== 404) {
            throw error;
          }
        }

        // Repository doesn't exist, create it
        console.log(`Creating repository '${repoName}' in ${organization}...`);

        await octokit.repos.createInOrg({
          org: organization,
          name: repoName,
          description: repo.description || '',
          private: repo.private === 'true' || repo.private === true,
          auto_init: repo.auto_init !== 'false', // Default to true
          allow_squash_merge: repo.allow_squash_merge !== 'false',
          allow_merge_commit: repo.allow_merge_commit !== 'false',
          allow_rebase_merge: repo.allow_rebase_merge !== 'false',
          delete_branch_on_merge: repo.delete_branch_on_merge === 'true'
        });

        console.log(`✓ Repository '${repoName}' created successfully`);
      } catch (error) {
        console.error(`✗ Error processing '${repoName}': ${error.message}`);
      }
    }

    console.log('Repository processing completed');
  } catch (error) {
    console.error(`Fatal error: ${error.message}`);
    process.exit(1);
  }
}

async function setRepoPermissions() {
  try {
    const csvFilePath = path.resolve('./csv/permissions.csv');
    console.log(`Reading repo permissions data from: ${csvFilePath}`);

    if (!fs.existsSync(csvFilePath)) {
      console.error(`Error: CSV file not found at ${csvFilePath}`);
      process.exit(1);
    }

    const csvContent = fs.readFileSync(csvFilePath, 'utf8');
    const permissions = parse(csvContent, { columns: true, skip_empty_lines: true });

    // Valid GitHub permission types for teams
    const validPermissions = ['pull', 'push', 'admin', 'maintain', 'triage'];

    for (const record of permissions) {
      const repoName = record.repository;
      const teamName = record.team;
      const permission = record.permission;

      if (!repoName || !teamName || !permission) {
        console.warn('Warning: Missing repository, team, or permission, skipping entry');
        continue;
      }

      // Validate permission type
      if (!validPermissions.includes(permission)) {
        console.warn(`Warning: Invalid permission '${permission}' for repo '${repoName}' and team '${teamName}', skipping entry`);
        continue;
      }

      // Validate repository exists
      let repoExists = false;
      try {
        await octokit.repos.get({
          owner: organization,
          repo: repoName
        });
        repoExists = true;
      } catch (error) {
        if (error.status === 404) {
          console.warn(`Warning: Repository '${repoName}' does not exist, skipping permission entry`);
          continue;
        } else {
          throw error;
        }
      }

      // Validate team exists
      let teamSlug = teamName.toLowerCase().replace(/ /g, '-');
      let teamExists = false;
      try {
        await octokit.rest.teams.getByName({
          org: organization,
          team_slug: teamSlug
        });
        teamExists = true;
      } catch (error) {
        if (error.status === 404) {
          console.warn(`Warning: Team '${teamName}' does not exist, skipping permission entry`);
          continue;
        } else {
          throw error;
        }
      }

      // Set permission if both exist
      try {
        await octokit.teams.addOrUpdateRepoPermissionsInOrg({
          org: organization,
          team_slug: teamSlug,
          owner: organization,
          repo: repoName,
          permission: permission
        });
        console.log(`✓ Set '${permission}' permission for team '${teamName}' on repo '${repoName}'`);
      } catch (error) {
        console.error(`✗ Error setting permission for team '${teamName}' on repo '${repoName}': ${error.message}`);
      }
    }

    console.log('Repository permissions processing completed');
  } catch (error) {
    console.error(`Fatal error: ${error.message}`);
    process.exit(1);
  }
}


async function createTeams() {
  try {
    // Read and parse CSV file
    const csvFilePath = path.resolve('./csv/teams.csv');
    console.log(`Reading team data from: ${csvFilePath}`);

    if (!fs.existsSync(csvFilePath)) {
      console.error(`Error: CSV file not found at ${csvFilePath}`);
      process.exit(1);
    }

    const csvContent = fs.readFileSync(csvFilePath, 'utf8');
    const teams = parse(csvContent, { columns: true, skip_empty_lines: true });

    console.log(`Found ${teams.length} teams to process`);

    // Process each team
    for (const team of teams) {
      const teamName = team.name;
      if (!teamName) {
        console.warn('Warning: Team name missing, skipping entry');
        continue;
      }

      if(!team.privacy) {
        console.warn('Warning: Team privacy missing, skipping entry');
        continue;
      }

      if(team.privacy !== 'closed' && team.privacy !== 'secret') {
        console.warn('Warning: Team privacy must be either "closed" or "secret", skipping entry');
        continue;
      }

      try {
        // Check if team already exists
        try {
          await octokit.rest.teams.getByName({
            org: organization,
            team_slug: teamName.toLowerCase().replace(/ /g, '-')
          });
          console.log(`✓ Team '${teamName}' already exists in ${organization}`);
          continue;
        } catch (error) {
          // Only proceed if the error is 404 (Not Found)
          if (error.status !== 404) {
            throw error;
          }
        }

        // Team doesn't exist, create it
        console.log(`Creating team '${teamName}' in ${organization}...`);

        await octokit.teams.create({
          org: organization,
          name: teamName,
          description: team.description || '',
          privacy: team.privacy
        });

        //set group idp connection in case all values are provided
        if(team.idpGroupId && team.idpGroupName && team.idpGroupDescription) {
          const url = `PATCH /orgs/${organization}/teams/${teamName}/team-sync/group-mappings`;
          console.log('debug url', url);
          await octokit.request(url, {
            org: organization,
            team_slug: teamName,
            groups: [
              {
                group_id: team.idpGroupId,
                group_name: team.idpGroupName,
                group_description: team.idpGroupDescription
              }
            ],
            headers: {
              'X-GitHub-Api-Version': '2022-11-28'
            }
          })

        } else {
          console.warn('Warning: Missing idpGroupId, idpGroupName, or idpGroupDescription, skipping idpGroupMembership');
        }
        
        console.log(`✓ Team '${teamName}' created successfully`);
      } catch (error) {
        console.error(`✗ Error processing team '${teamName}': ${error.message}`);
      }
    }

    console.log('Team processing completed');
  } catch (error) {
    console.error(`Fatal error: ${error.message}`);
    process.exit(1);
  }
}

async function main() {
  await createTeams();
  await createRepositories();
  await setRepoPermissions();
  console.log('GitHub automation script completed successfully');
}

main();