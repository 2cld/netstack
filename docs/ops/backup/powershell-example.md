
# tl;dr
- from [this link](https://superuser.com/questions/748069/how-do-i-compare-two-folders-recursively-and-generate-a-list-of-files-and-folder)
```powershell
C:\>robocopy.exe source target /l /e /zb /xx /xl /fp /ns /nc /ndl /np /njh /njs

                                C:\source\foo\bar\b.txt
```

## Details & Explanation of Options
Robocopy (Wikipedia) seems widely adopted for Windows system administration; is well-documented (TechNet); is discussed as more than an obscurity on Stack Overflow, Server Fault, and of course, here at Super User; provides for a specific function rather than trying to be a multi-purpose tool (which tend toward bloat and bugs); and furthermore has been providing this specific function since 1997. For me, all these factors contribute to "transparency," despite it being closed-source, and set my mind at ease.

Robocopy comes as part of a set of tools currently known as Windows Server 2003 Resource Kit Tools. After downloading and installing, I recreated the scenario in my question and gave it a go:

```powershell
C:\>robocopy.exe source target /l /e /zb

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Thu May 01 09:08:20 2014

   Source : C:\source\
     Dest : C:\target\

    Files : *.*

  Options : *.* /L /S /E /COPY:DAT /ZB /R:1000000 /W:30

------------------------------------------------------------------------------

                           0    C:\source\
                           1    C:\source\foo\
        *EXTRA Dir        -1    C:\target\foo\baz\
                           2    C:\source\foo\bar\
          *EXTRA File                  1        d.txt
            Newer                      5        b.txt
            New File                   1        c.txt

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         3         0         3         0         0         1
   Files :         3         2         1         0         0         1
   Bytes :         7         6         1         0         0         1
   Times :   0:00:00   0:00:00                       0:00:00   0:00:00

   Ended : Thu May 01 09:08:20 2014
```

- Looks good! Let me explain the options:
```txt
/l lists actions without actually carrying them out.
/e includes subdirectories, but unlike /s, includes empty directories too.
/zb copies in "restart" mode, and on access denied, "backup" mode; it seems like the safest approach; read more here.
```
- I didn't need any of the copy-related options since I'm not actually performing any actions.
- Anyway, next, it was only a matter of adding more switches to get the output I desired:
```powershell
C:\>robocopy.exe source target /l /e /zb /xx /xl /fp /ns /nc /ndl /np /njh /njs

                                C:\source\foo\bar\b.txt
```
- Again, let's go through the options.
- First, I only cared about modified files and folders, so:
```txt
/xx excludes "extra" files and directories—those which exist only in the target.
/xl excludes "lonely" files and directories—those which exist only in the source.
```
- Second, I desired relative paths (or at least full paths, not just names):
```
/fp enables full paths (unsurprisingly, there was no option for relative paths).
```
- Third, I wanted to remove as much logging fluff as possible, and I was pleasantly surprised to find that all of it was removable:
```
/ns suppresses file sizes.
/nc suppresses classes, e.g. Newer.
/ndl suppresses directory names.
/np suppresses copy progress output.
/njh suppresses the job header.
/njs suppresses the job summary.
```
