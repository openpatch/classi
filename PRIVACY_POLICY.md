# Privacy Policy for Classi

**Effective date:** 2026-04-28
**Last updated:** 2026-04-28

This Privacy Policy describes how **OpenPatch** ("we", "us", or "our") handles
information in connection with the **Classi** mobile and desktop application
("the App"). Please read this policy carefully. By using the App you confirm
that you have read and understood it.

---

## 1. Who We Are

Classi is developed and maintained by **OpenPatch**. If you have any questions
or concerns about this Privacy Policy you may contact us at:

- **GitHub:** <https://github.com/openpatch/classi/issues>

---

## 2. Summary

> **Classi is a local-first application. It does not collect, transmit, or share
> any personal data with us or any third party.** All data you enter — including
> student names, grades, notes, and checklists — is stored exclusively on your
> own device in an encrypted database file that you control.

---

## 3. Information the App Stores on Your Device

To deliver its teaching-management features, Classi stores the following
categories of data **locally on your device only**:

| Category | Examples |
|---|---|
| Group / class data | Group names, academic year labels |
| Student data | First name, last name, archived status, avatar |
| Academic records | Grades, grade systems, grade history |
| Notes | Free-text notes linked to students or groups |
| Checklists | Checklist titles, items, and student-linked status |
| Material tracking | Material names and per-student tracking status |
| App settings | Chosen library path, auto-backup preferences, language |
| Security credentials | Encrypted passphrase hash, recovery key (stored in the OS secure keystore) |

None of this data is ever sent to our servers, any analytics service, or any
third party.

---

## 4. Data We Do Not Collect

We do **not** collect:

- Names, email addresses, or any personally identifiable information about you
  as the teacher or about your students
- Usage analytics, crash reports, or telemetry
- Location data
- Device identifiers or advertising IDs
- Payment information

The App has **no network features** and makes no outbound connections of any
kind.

---

## 5. Encryption and Security

All library data is stored in a **SQLCipher-encrypted** `.classi` database file
protected by a passphrase you choose during first-run setup. A recovery key is
generated at setup time so you can regain access if you forget your passphrase.

The passphrase is stored in the device's **secure keystore**
(`flutter_secure_storage`) and never leaves your device.

Optionally, you may enable **biometric unlock** (fingerprint / face). In that
case the App stores the database passphrase in the OS secure keystore under a
biometric-protected key, using the platform biometrics API (`local_auth`). No
biometric data is accessed or stored by the App itself — this is handled
entirely by the operating system.

---

## 6. Backups and Exports

If you enable **auto-export backups**, the App writes a `.classi-backup` file to
a folder you select on your device. This file is a portable, encrypted copy of
your library. It remains on your device; we have no access to it.

You are responsible for the security of any backup files you store, share, or
transfer (e.g. via cloud storage, e-mail, or USB).

---

## 7. Permissions

The App requests only the permissions necessary to function:

| Permission | Purpose |
|---|---|
| **Storage / Files (READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, MANAGE_EXTERNAL_STORAGE on Android 10 and lower)** | Reading and writing the `.classi` library folder and backup files you choose |
| **Biometric / Fingerprint (USE_BIOMETRIC, USE_FINGERPRINT)** | Optional biometric unlock; only requested if you enable the feature |

No other device permissions are required or requested.

---

## 8. Children's Privacy

Classi is a tool **for teachers**, not for use directly by children. Although
teachers may enter student names and academic records, these records are stored
locally on the teacher's device and are never transmitted. We do not knowingly
collect any data from individuals under the age of 13 through the App.

---

## 9. Data Retention and Deletion

Because all data is stored on your device, you are in full control of retention:

- **Deleting a library:** Remove the `.classi` folder from your device to
  permanently erase all data.
- **Uninstalling the App:** Uninstalling the App removes app-private data. If
  you stored your library in shared storage (recommended), the `.classi` folder
  will remain until you manually delete it.
- **Secure storage:** Passphrase entries in the OS secure keystore are removed
  when you uninstall the App on most Android versions.

---

## 10. Third-Party Libraries

Classi uses open-source Flutter packages to deliver its functionality. The
libraries listed below run entirely on-device and do not transmit data:

| Package | Purpose |
|---|---|
| `drift` / `sqlite3mc` | Encrypted local database |
| `flutter_secure_storage` | Secure keystore access |
| `local_auth` | Biometric unlock |
| `file_picker` | Folder and file selection dialogs |
| `easy_localization` | UI translations (English and German) |
| `go_router` | In-app navigation |
| `fl_chart` | Grade history charts |
| `avatar_maker` | Student avatar creation |

None of these libraries collect or transmit personal data.

---

## 11. Changes to This Policy

We may update this Privacy Policy from time to time. When we do, we will update
the **"Last updated"** date at the top of this document and publish the new
version in the repository. Continued use of the App after an update constitutes
acceptance of the revised policy.

---

## 12. Contact

If you have questions, concerns, or requests related to this Privacy Policy,
please open an issue on our GitHub repository:

<https://github.com/openpatch/classi/issues>

---

*Classi is open-source software released under the
[MIT License](LICENSE).*
