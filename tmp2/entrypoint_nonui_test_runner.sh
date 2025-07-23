#!/bin/bash
set -e

echo "Running non-UI .NET tests..."
dotnet test /home/app/UITests.Shared/UITests.Shared.csproj \
  --logger:"trx;LogFileName=test-results.trx" \
  --logger:"console;verbosity=normal" \
  --results-directory /home/app/output 

echo "Non-UI tests completed."
