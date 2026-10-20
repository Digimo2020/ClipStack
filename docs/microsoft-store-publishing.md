# Microsoft Store publishing

## ClipStack Windows package

ClipStack is an Electron app packaged as a 64-bit NSIS installer (`ClipStack-Setup.exe`). GitHub Actions builds the installer and publishes it to GitHub Releases. The current installer is unsigned, so it is not ready for Microsoft Store EXE submission.

Before submitting the EXE, prepare a trusted code-signing certificate and sign the installer and its included executable files. Confirm the installer supports silent installation and installs offline. Host each signed release at a stable, version-specific HTTPS URL; do not replace the binary at a submitted URL.

## Partner Center steps

1. Register for a Microsoft Store developer account at <https://storedeveloper.microsoft.com/>. Choose Individual to publish under your own name, or Company to publish under a registered business. Microsoft's current registration flow has no fee; account type cannot later be changed.
2. In Partner Center, open **Apps and games → New product → EXE or MSI app**. Check whether **ClipStack** is available, then reserve the name.
3. Complete the submission:
   - **Availability:** choose price and markets.
   - **Properties:** choose a category and enter supported Windows requirements.
   - **Age ratings:** complete the IARC questionnaire.
   - **Packages:** provide the versioned HTTPS installer URL, choose **EXE** and **x64**, and enter the silent-install parameter.
   - **Store listings:** provide the description, at least one screenshot, and a square Store logo. Add support and privacy information.
4. Save the sections, review the submission, and select **Submit** for certification.

## Listing assets

The product artwork below is promotional art. Use real ClipStack screenshots for the required Store screenshots. Create a square Store logo separately if Partner Center requests it.

![ClipStack product artwork](microsoft-store-product.png)

## Privacy description

Describe that ClipStack captures clipboard text and images, stores its history locally, and does not upload clipboard contents. Include a support contact and a privacy statement URL in the listing.

## Microsoft references

- [Developer account registration](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account)
- [Get started with Store submissions](https://learn.microsoft.com/en-us/windows/apps/publish/get-started)
- [EXE/MSI package requirements](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements)
- [EXE/MSI package submission fields](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/upload-app-packages)
- [EXE/MSI certification process](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-certification-process)
