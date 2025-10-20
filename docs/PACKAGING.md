## Description

Apex Error Logger is packaged as an Unmanaged Package for easy installation across orgs without namespace prefixes. This package ships the custom object `Error_Log__c`, its fields, six Apex classes, and two permission sets. Use this guide to assemble and upload versioned unmanaged packages and publish install links.

Key points:
- No namespace is applied in unmanaged packaging; metadata deploys exactly as-is.
- Keep API names stable; future Managed Package migration will require a reserved namespace but the same metadata layout.
- Include only supported components; tests are included for verification but are optional for install.

## Build Unmanaged Package (Step-by-step)

This project is designed for an unmanaged package to simplify installation.

### Prerequisites
- A Salesforce org where you can create and upload packages (Sandbox or Production)
- The metadata deployed to that org (use `sf project deploy start` if needed)

### 1) Create Package
1. Go to Setup → Package Manager (a.k.a. Packages)
2. Click "New"
3. Name: Apex Error Logger
4. Type: Unmanaged
5. Save

### 2) Add Components
1. In the package, click "Add" and include components from this project:
   - Custom Object: `Error_Log__c` + all its fields
   - Apex Classes: `ErrorLogger`, `ErrorLoggerTest`, `HttpClient`, `FlowErrorLogger`, `LoggingFinalizer`, `EventLogCollector`
   - Permission Sets: `Error_Log_Admin`, `Error_Log_Viewer`
2. Save

### 3) Upload Package
1. Click "Upload"
2. Version Name: 1.0.0, Version Number: 1.0.0.0
3. Select your org types (Sandbox/Production)
4. Upload

### 4) Get Installation URL(s)
- After upload completes, copy the install links.
- Each successful upload generates an Id starting with `04t` (the Package Version Id).

Note: The installation URLs are shown immediately after the upload completes and remain available on the Package Version detail page. You can revisit the package in Setup → Package Manager → your package → Versions → click the version to copy the links again.

Production/Developer URL:
`https://login.salesforce.com/packaging/installPackage.apexp?p0=<04t...>`

Sandbox URL:
`https://test.salesforce.com/packaging/installPackage.apexp?p0=<04t...>`

### 5) Update Documentation
- Replace placeholders in `README.md` and `RELEASE_NOTES_v1.0.0.md`
- Commit and push the changes

### Alternative: SFDX (Unlocked/Managed)
This repository is structured for source development (SFDX), but unmanaged packaging for distribution is recommended for ease. If you plan to convert to unlocked/second-gen packaging, you need a Dev Hub and to adjust `sfdx-project.json` accordingly.

## Managed Package (Coming Soon)

A namespaced, second-generation managed package (2GP) is planned. When available:
- Install links (Production/Sandbox) will be added to the README and Releases.
- Versioned updates will be published via GitHub Releases.
- Backwards-compatible metadata and API names will be maintained.

Until then, use the Unmanaged Package steps above. Follow the repository to be notified when the managed package is published.

## Post-Installation

- The package appears under Setup → Installed Packages after installation.
- You can open the package detail view from Installed Packages to review components, uninstall, or manage package-level settings.
- Assign permission sets to users as needed: `Error_Log_Admin`, `Error_Log_Viewer`.

## Test Coverage Requirements (Production)

Salesforce requires at least 75% aggregate Apex code coverage in the target org to deploy or install Apex into Production. Key points:

- Aggregate coverage is calculated across all Apex classes and triggers in the org, not only this package.
- All triggers must have some test coverage (non-zero).
- Tests included in this package only cover the package’s classes; they can’t raise coverage for unrelated org classes.

How to check coverage
- Setup → Apex Test Execution → Run All Tests (or a suite) → View Overall Code Coverage.
- CLI: `sf apex run test --test-level RunLocalTests --target-org YOUR_PROD_ALIAS --wait 30` then `sf apex get codecoverage --target-org YOUR_PROD_ALIAS`.

If your org shows 62% (example)
- Identify low-coverage classes in the coverage report and add unit tests for them. Only covering existing low-coverage classes increases the aggregate.
- Avoid adding dummy classes; they increase total lines and don’t help coverage.
- Consider installing to a Sandbox first. Promote to Production after fixing org-wide coverage.

Packaging tip
- Perform the unmanaged package upload from a clean packaging org (Dev/Partner/DE) with high coverage (this repo’s tests pass at 100%). Installation into customer orgs will still require their org to meet 75%.
