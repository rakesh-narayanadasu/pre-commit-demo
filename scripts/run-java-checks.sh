#!/bin/bash
set -e

failures=()

echo "🔍 [Maven Checks] Running Spotless..."
if ! mvn spotless:check -q; then
  echo "❌ Maven Checks (Spotless) ---- FAILED"
  failures+=("Spotless")
else
  echo "✅ Maven Checks (Spotless) ---- PASSED"
fi

echo "🔍 [Maven Checks] Running Checkstyle..."
if ! mvn checkstyle:check -q; then
  echo "❌ Maven Checks (Checkstyle) ---- FAILED"
  failures+=("Checkstyle")
else
  echo "✅ Maven Checks (Checkstyle) ---- PASSED"
fi

echo "🔍 [Maven Checks] Running Unit Tests..."
if ! mvn test -q; then
  echo "❌ Maven Checks (Tests) ---- FAILED"
  failures+=("Tests")
else
  echo "✅ Maven Checks (Tests) ---- PASSED"
fi

echo "🔍 [Maven Checks] Generating JaCoCo Coverage Report..."
if ! mvn jacoco:report -q; then
  echo "❌ Maven Checks (Coverage Report Generation) ---- FAILED"
  failures+=("Coverage Report")
fi

COVERAGE_FILE="target/site/jacoco/jacoco.xml"
if [ -f "$COVERAGE_FILE" ]; then
  COVERED=$(grep -oPm1 "(?<=<counter type=\"INSTRUCTION\" missed=\"\d+\" covered=\")\d+" "$COVERAGE_FILE")
  if [ "$COVERED" -lt 80 ]; then
    echo "❌ Maven Checks (Coverage < 80%) ---- FAILED ($COVERED%)"
    failures+=("Coverage < 80%")
  else
    echo "✅ Maven Checks (Coverage >= 80%) ---- PASSED ($COVERED%)"
  fi
else
  echo "❌ Maven Checks (Coverage XML not found) ---- FAILED"
  failures+=("Coverage File Missing")
fi

# Show result summary
if [ ${#failures[@]} -ne 0 ]; then
  echo ""
  echo "🚫 Commit blocked due to the following failed checks:"
  for fail in "${failures[@]}"; do
    echo " - $fail"
  done
  exit 1
else
  echo ""
  echo "✅ All Maven checks passed!"
fi
