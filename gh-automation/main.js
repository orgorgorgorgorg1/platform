/**
 * GitHub Repository Automation Script
 * 
 * Reads repository information from a CSV file and creates repositories
 * in a GitHub Enterprise organization if they don't already exist.
 */

import fs from 'fs';
import path from 'path';
import { parse } from 'csv-parse/sync'; // Using sync for simplicity
import { Octokit } from '@octokit/rest';

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
const octokit = new Octokit({ auth: token,
  baseUrl: process.env.GITHUB_API_URL,
 });

async function main() {
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

main();