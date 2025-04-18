#!/bin/bash

# filepath: c:\code\platform\tf\repositories\import.sh

#requires rewrite to read all teams from GitHub API!! and use id's

# Set paths to CSV files
REPOS_CSV="csv/repos.csv"
TEAMS_CSV="csv/teams.csv"

# Check if repos.csv exists
if [[ ! -f "$REPOS_CSV" ]]; then
  echo "Error: $REPOS_CSV not found!"
  exit 1
fi

# Check if teams.csv exists
if [[ ! -f "$TEAMS_CSV" ]]; then
  echo "Error: $TEAMS_CSV not found!"
  exit 1
fi

# Import GitHub repositories
echo "Importing GitHub repositories..."
while IFS=',' read -r name description private; do
  # Skip the header row
  if [[ "$name" == "name" ]]; then
    continue
  fi

  echo "Importing repository: $name"
  terraform import repositories.repositories.github_repository "$name"
  terraform import repositories.github_team_repository.team_permissions "$Group:$Repository"
done < "$REPOS_CSV"

# Import GitHub teams
echo "Importing GitHub teams..."
while IFS=',' read -r name description privacy; do
  # Skip the header row
  if [[ "$name" == "name" ]]; then
    continue
  fi

  echo "Importing team: $name"
  terraform import teams.github_team.teams "$name"
done < "$TEAMS_CSV"

echo "Import completed!"