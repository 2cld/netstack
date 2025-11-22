# hyper-v nested virtualization

- stop vm
- PowerShell to enable
```
Set-VMProcessor -VMName "Your Ubuntu VM Name" -ExposeVirtualizationExtensions $true
```
- start vm ssh into vm
- cat /proc/cpuinfo | grep -E 'vmx|svm'
