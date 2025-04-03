#!/bin/bash

# filepath: c:\code\platform\tf\repositories\import.sh

# Set paths to CSV files
REPOS_CSV="tf/csv/repos.csv"
TEAMS_CSV="tf/csv/teams.csv"

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
  terraform import github_repository.terraform "$name"
done < "$REPOS_CSV"

# Import GitHub teams
echo "Importing GitHub teams..."
while IFS=',' read -r name description privacy; do
  # Skip the header row
  if [[ "$name" == "name" ]]; then
    continue
  fi

  echo "Importing team: $name"
  terraform import github_team.core "$name"
done < "$TEAMS_CSV"

echo "Import completed!"