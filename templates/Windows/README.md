

# Notes on testing vm templates

## Downloading ISO images

```shell
$ cd /data/datacenter/jenkins/osimages/
$ BASE_URL="https://nextcloud.media.dettonville.cloud"
$ nohup curl --progress-bar -fsL -o windows-SRV2016.ENU.JUL2017.14393-1532.iso "${BASE_URL}/s/7xFwkKxTBmFH2iP/download/windows-SRV2016.ENU.JUL2017.14393-1532.iso" &
$ nohup curl --progress-bar -fsL -o windows-SRV2019.DC.ENU.MAY2021.iso "${BASE_URL}/s/o8YaxbdcK3FbDBa/download/windows-SRV2019.DC.ENU.MAY2021.iso" &
$ nohup curl --progress-bar -fsL -o windows-SRV2022.LTSC.21H2.Build-20348.1006.iso "${BASE_URL}/s/fNKa799nq9FQdBf/download/windows-SRV2022.LTSC.21H2.Build-20348.1006.iso" &

```

## Setting up the autounattend.xml password

```powershell
## encoding
$UnEncodedText = 'IamAdminPassword'
$EncodedText =[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($UnEncodedText))
write-host "Encoded_String_is:" $EncodedText
Encoded_String_is: SQBhAG0AQQBkAG0AaQBuAFAAYQBzAHMAdwBvAHIAZAA=

## decoding
$EncodedText = 'SQBhAG0AQQBkAG0AaQBuAFAAYQBzAHMAdwBvAHIAZAA='
$DecodedText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedText))
write-host "Decoded_Text_is:" $DecodedText
Decoded_Text_is: IamAdminPassword
```


# Reference

* https://github.com/vmware-samples/packer-examples-for-vsphere
* https://github.com/vmware-samples/packer-examples-for-vsphere/tree/main/builds/windows

