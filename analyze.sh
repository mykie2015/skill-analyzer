#!/bin/bash

# Skill Analyzer - Analyze Claude Code / OpenClaw skills and generate HTML reports

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if URL provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: bash analyze.sh <github-url>${NC}"
    echo "Examples:"
    echo "  bash analyze.sh https://github.com/JimLiu/baoyu-skills"
    echo "  bash analyze.sh jimliu/baoyu-skills"
    exit 1
fi

# Parse GitHub URL
INPUT="$1"
if [[ "$INPUT" =~ ^https?://github\.com/([^/]+)/([^/]+)/?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
elif [[ "$INPUT" =~ ^([^/]+)/([^/]+)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    echo -e "${RED}Invalid GitHub URL format${NC}"
    exit 1
fi

GITHUB_URL="https://github.com/${OWNER}/${REPO}"
CLONE_DIR="/tmp/skill-analyzer-${REPO}-$$"

echo -e "${BLUE}🔍 Analyzing skill: ${OWNER}/${REPO}${NC}"

# Clone the repository
echo -e "${BLUE}📦 Cloning repository...${NC}"
git clone --depth 1 "$GITHUB_URL" "$CLONE_DIR" 2>/dev/null || {
    echo -e "${RED}Failed to clone repository${NC}"
    exit 1
}

cd "$CLONE_DIR"

# Extract information
SKILL_NAME="$REPO"
DESCRIPTION=""
COMMANDS=""
DEPENDENCIES=""
WHAT_IT_DOES=""
SAFETY_NOTES=""
USE_CASES=""

# Function to escape HTML
escape_html() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Function to convert markdown to simple HTML
md_to_html() {
    sed 's/^### \(.*\)/<h3>\1<\/h3>/g' | \
    sed 's/^## \(.*\)/<h2>\1<\/h2>/g' | \
    sed 's/^# \(.*\)/<h1>\1<\/h1>/g' | \
    sed 's/^\* \(.*\)/<li>\1<\/li>/g' | \
    sed 's/^- \(.*\)/<li>\1<\/li>/g' | \
    sed 's/`\([^`]*\)`/<code>\1<\/code>/g' | \
    sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g'
}

# Read SKILL.md
if [ -f "SKILL.md" ]; then
    echo -e "${BLUE}📄 Reading SKILL.md...${NC}"
    
    # Extract skill name from first heading
    SKILL_NAME_FROM_FILE=$(grep -m 1 "^# " SKILL.md | sed 's/^# //' || echo "")
    if [ -n "$SKILL_NAME_FROM_FILE" ]; then
        SKILL_NAME="$SKILL_NAME_FROM_FILE"
    fi
    
    # Extract description (first paragraph after title)
    DESCRIPTION=$(awk '/^# /{flag=1; next} flag && /^[^#]/ && NF {print; exit}' SKILL.md)
    
    # Extract commands section
    COMMANDS=$(awk '/^## (Commands|Usage|CLI)/{flag=1; next} /^## /{flag=0} flag' SKILL.md | md_to_html)
    
    # Extract what it does
    WHAT_IT_DOES=$(awk '/^## (What|Description|Overview)/{flag=1; next} /^## /{flag=0} flag' SKILL.md | md_to_html)
    
    # Extract safety notes
    SAFETY_NOTES=$(awk '/^## (Safety|Security|Warning)/{flag=1; next} /^## /{flag=0} flag' SKILL.md | md_to_html)
fi

# Read README.md if SKILL.md doesn't exist or for additional info
if [ -f "README.md" ]; then
    echo -e "${BLUE}📄 Reading README.md...${NC}"
    
    if [ -z "$DESCRIPTION" ]; then
        DESCRIPTION=$(awk '/^# /{flag=1; next} flag && /^[^#]/ && NF {print; exit}' README.md)
    fi
    
    if [ -z "$WHAT_IT_DOES" ]; then
        WHAT_IT_DOES=$(awk '/^## (What|Description|Overview|Features)/{flag=1; next} /^## /{flag=0} flag' README.md | md_to_html)
    fi
    
    # Extract use cases
    USE_CASES=$(awk '/^## (Use Cases|Examples|Usage)/{flag=1; next} /^## /{flag=0} flag' README.md | md_to_html)
fi

# Read package.json for dependencies
if [ -f "package.json" ]; then
    echo -e "${BLUE}📦 Reading package.json...${NC}"
    
    DEPS=$(grep -A 100 '"dependencies"' package.json | grep -B 100 '^  }' | grep '"' | sed 's/[",]//g' | awk '{print "<li>" $1 " " $2 "</li>"}' || echo "")
    if [ -n "$DEPS" ]; then
        DEPENDENCIES="<ul>$DEPS</ul>"
    fi
fi

# Scan all .md files for additional context
echo -e "${BLUE}🔎 Scanning markdown files...${NC}"
ALL_MD_CONTENT=$(find . -name "*.md" -type f -exec cat {} \; 2>/dev/null || echo "")

# If still missing info, try to extract from all markdown
if [ -z "$WHAT_IT_DOES" ]; then
    WHAT_IT_DOES=$(echo "$ALL_MD_CONTENT" | head -20 | md_to_html)
fi

# Set defaults if empty
[ -z "$DESCRIPTION" ] && DESCRIPTION="A Claude Code / OpenClaw skill"
[ -z "$WHAT_IT_DOES" ] && WHAT_IT_DOES="<p>This skill extends Claude Code / OpenClaw capabilities.</p>"
[ -z "$COMMANDS" ] && COMMANDS="<p>See repository documentation for available commands.</p>"
[ -z "$DEPENDENCIES" ] && DEPENDENCIES="<p>No dependencies listed</p>"
[ -z "$SAFETY_NOTES" ] && SAFETY_NOTES="<p>Review the source code before use. Follow standard security practices.</p>"
[ -z "$USE_CASES" ] && USE_CASES="<p>Check the repository for examples and use cases.</p>"

# Generate HTML report
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/template.html"
OUTPUT_FILE="$SCRIPT_DIR/reports/${REPO}.html"

echo -e "${BLUE}📝 Generating HTML report...${NC}"

# Read template and replace placeholders
TEMPLATE=$(cat "$TEMPLATE_FILE")

# Replace placeholders
REPORT="${TEMPLATE//\{\{SKILL_NAME\}\}/$SKILL_NAME}"
REPORT="${REPORT//\{\{DESCRIPTION\}\}/$DESCRIPTION}"
REPORT="${REPORT//\{\{GITHUB_URL\}\}/$GITHUB_URL}"
REPORT="${REPORT//\{\{WHAT_IT_DOES\}\}/$WHAT_IT_DOES}"
REPORT="${REPORT//\{\{COMMANDS\}\}/$COMMANDS}"
REPORT="${REPORT//\{\{DEPENDENCIES\}\}/$DEPENDENCIES}"
REPORT="${REPORT//\{\{SAFETY_NOTES\}\}/$SAFETY_NOTES}"
REPORT="${REPORT//\{\{USE_CASES\}\}/$USE_CASES}"
REPORT="${REPORT//\{\{REPO_NAME\}\}/${OWNER}/${REPO}}"

# Write report
echo "$REPORT" > "$OUTPUT_FILE"

# Cleanup
cd /
rm -rf "$CLONE_DIR"

# Generate raw.githack link
RAWGITHACK_URL="https://raw.githack.com/mykie2015/skill-analyzer/main/reports/${REPO}.html"

echo -e "${GREEN}✅ Analysis complete!${NC}"
echo -e "${GREEN}📊 Report saved to: reports/${REPO}.html${NC}"
echo -e "${GREEN}🔗 Raw.githack link: ${RAWGITHACK_URL}${NC}"
echo ""
echo "To view locally: open reports/${REPO}.html"
echo "To share: Push to GitHub and use the raw.githack link above"
