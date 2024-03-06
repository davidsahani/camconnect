# CamConnect Desktop

This project is desktop implementation of the CamConnect project.

## Project Configurations to Consider

### For Windows:

**Metadata configuration:** Application metadata can be configured in the `windows/runner/Runner.rc` file.

```rc
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904e4"
        BEGIN
            VALUE "CompanyName", "com.project.camconnect" "\0"
            VALUE "FileDescription", "camconnect" "\0"
            VALUE "FileVersion", VERSION_AS_STRING "\0"
            VALUE "InternalName", "camconnect" "\0"
            VALUE "LegalCopyright", "Copyright (C) 2024 davidsahani@github.com. All rights reserved." "\0"
            VALUE "OriginalFilename", "camconnect.exe" "\0"
            VALUE "ProductName", "camconnect" "\0"
            VALUE "ProductVersion", VERSION_AS_STRING "\0"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1252
    END
END
```