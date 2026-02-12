# Skill Analyzer

Analyze any Claude Code / OpenClaw skill repository and generate a beautiful, mobile-friendly HTML report.

## What It Does

Skill Analyzer clones a GitHub skill repository, extracts key information from markdown files and package.json, then generates a clean, mobile-optimized HTML report with:

- Skill name and description
- What it does (plain language)
- Available commands
- Dependencies
- Safety notes
- Use cases

The generated reports are:
- **Mobile-first** - Optimized for iPhone 14 Pro (375px) and larger screens
- **Touch-friendly** - Smooth interactions and readable typography
- **Self-contained** - No external dependencies, works offline
- **Dark mode** - Toggle between light and dark themes
- **Xiaohongshu/Notion inspired** - Clean, modern design

## Usage

```bash
bash analyze.sh <github-url>
```

### Examples

Full GitHub URL:
```bash
bash analyze.sh https://github.com/JimLiu/baoyu-skills
```

Shorthand format:
```bash
bash analyze.sh jimliu/baoyu-skills
```

## Output

The script will:
1. Clone the repository to `/tmp`
2. Extract information from SKILL.md, README.md, package.json, and other markdown files
3. Generate an HTML report at `reports/<skill-name>.html`
4. Output a raw.githack link for easy sharing

Example output:
```
🔍 Analyzing skill: JimLiu/baoyu-skills
📦 Cloning repository...
📄 Reading SKILL.md...
📄 Reading README.md...
📦 Reading package.json...
🔎 Scanning markdown files...
📝 Generating HTML report...
✅ Analysis complete!
📊 Report saved to: reports/baoyu-skills.html
🔗 Raw.githack link: https://raw.githack.com/mykie2015/skill-analyzer/main/reports/baoyu-skills.html

To view locally: open reports/baoyu-skills.html
To share: Push to GitHub and use the raw.githack link above
```

## Files

- **analyze.sh** - Main analysis script
- **template.html** - HTML template with embedded CSS/JS
- **reports/** - Generated HTML reports (git-ignored except .gitkeep)

## Requirements

- bash
- git
- Standard Unix tools (grep, sed, awk)

## How It Works

1. **Parse input** - Accepts full GitHub URLs or shorthand format
2. **Clone repo** - Shallow clone to `/tmp` for fast analysis
3. **Extract data** - Scans SKILL.md, README.md, package.json, and all .md files
4. **Generate HTML** - Replaces template placeholders with extracted content
5. **Output** - Saves report and provides raw.githack link

The script uses simple text processing (grep/sed/awk) to extract:
- Skill name from headings
- Description from first paragraph
- Commands from relevant sections
- Dependencies from package.json
- Safety notes and use cases from markdown

## Sharing Reports

After generating a report, push to GitHub:

```bash
git add reports/
git commit -m "Add analysis for <skill-name>"
git push
```

Then share the raw.githack link:
```
https://raw.githack.com/mykie2015/skill-analyzer/main/reports/<skill-name>.html
```

## License

MIT
