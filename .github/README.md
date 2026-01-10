# GitHub Workflows

This directory contains GitHub Actions workflows for automated testing and maintenance.

## Workflows

### Test Download Links (`test-download-links.yml`)

**Purpose:** Automatically test all download links in `config/downloads.json` to ensure they remain accessible.

**Schedule:** Runs every Monday at 9:00 AM UTC

**Triggers:**
- Scheduled (weekly)
- Manual trigger via GitHub UI
- On push to `config/downloads.json`

**What it does:**
1. Tests all URLs in the configuration file
2. Reports success/failure for each link
3. Creates/updates a GitHub issue if links are broken
4. Uploads test results as artifacts

**Tested URLs:**
- SPD Flash Tool download link
- USB driver download links
- Firmware source links

**Output:**
- Console output with color-coded results
- `link-test-results.json` artifact
- Automatic issue creation on failure with label `download-links`

## Running Workflows Manually

### Via GitHub UI
1. Go to the "Actions" tab
2. Select "Test Download Links" workflow
3. Click "Run workflow"
4. Choose branch and click "Run workflow"

### Via GitHub CLI
```bash
gh workflow run test-download-links.yml
```

## Viewing Results

### Console Output
1. Go to Actions tab
2. Click on the workflow run
3. Click on "Test Download Links" job
4. View the step outputs

### Artifacts
1. Go to the completed workflow run
2. Scroll to "Artifacts" section
3. Download `link-test-results.json`

### Issues
If links fail, an issue will be automatically created with:
- Title: "🔗 Download Links Test Failed"
- Labels: `download-links`, `automated`, `bug`
- Body: Details of failed links with URLs and errors

## Maintenance

### Updating Download Links
1. Edit `config/downloads.json`
2. Update the `url` fields with new working links
3. Optionally update SHA256 hashes
4. Commit and push changes
5. The workflow will automatically test new links

### Modifying the Workflow
Edit `.github/workflows/test-download-links.yml` to:
- Change schedule (modify `cron` expression)
- Add more link tests
- Adjust timeout values
- Modify issue creation behavior

## Troubleshooting

### Workflow Fails to Run
- Check repository settings → Actions → General
- Ensure workflows are enabled
- Check branch protection rules

### False Positives
Some websites may:
- Block automated requests
- Require user interaction (captcha)
- Have temporary downtime

In these cases, manually verify the link before updating the config.

### Rate Limiting
GitHub Actions may be rate-limited by target websites. If this occurs:
- Adjust request timeout
- Add delays between requests
- Use alternative download sources

---

**Last Updated:** 2026-01-10
