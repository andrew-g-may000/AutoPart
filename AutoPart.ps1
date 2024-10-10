############################################################################################

#############**! AutoPart v.1.0.1 (Automatic Random Partitioning Script) !**################

############################################################################################

Clear-Host

$ErrorActionPreference = "Stop"

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

############################################################################################

Get-Disk

$which_disk = Read-Host "`r`nWhich disk would you like to use?"

if ($which_disk -eq 0) {
    "`r`n*ERROR*: For your protection, this script cannot be used to format Physical Drive 0! Please rerun 'AutoPart.ps1' and try again..." | Red
    Start-Sleep -Seconds 10
    Exit
} elseif ($which_disk -match "[a-zA-Z]") {
    "`r`n*ERROR*: Invalid drive number received! Input must be a positive integer..." | Red
    Start-Sleep -Seconds 10
    Exit
} 

"`r`nWARNING: Running this script will format Physical Drive $which_disk! If you do NOT wish to proceed, please type '0' in the following prompt." | Red

$number_of_parts = Read-Host "`r`nHow many partitions do you need?"
if ($number_of_parts -eq 0) {
    "`r`n**Script exited successfully!**" | Red
    Start-Sleep -Seconds 10
    Exit
}

$size = Get-CimInstance Win32_DiskDrive | Where-Object {$_.DeviceID -like "*$which_disk*" } | Select-Object Size | Format-Table -HideTableHeaders | Out-String
$size_int = [int64]$size

$total_storage = $size_int
$max_part_size = [math]::Floor($total_storage / 12)
$list_of_parts = @()

    while ($number_of_parts -ne 0) {
        if ($max_part_size -gt 2048) {
            $rand_part = Get-Random -Minimum 2048 -Maximum $max_part_size
        } 
        else {
            break  
        }
        $round_rand = [math]::Floor($rand_part)
        if ($round_rand -lt $total_storage) {
            $total_storage -= $round_rand
            $list_of_parts += $round_rand
            $number_of_parts-=1
            }
        else {
            "You have run out of space on this volume!"
            break
            }

        }

"Number of partitions: " + $list_of_parts.length
$list_of_parts

"Storage Space Remaining: " + $total_storage + " Bytes"

clear-disk -number $which_disk -removedata -RemoveOEM

Set-Disk -Number $which_disk -PartitionStyle GPT
Start-Transcript -Path .\part_info.txt -Append

$count = 1
foreach ($i in $list_of_parts) {
    New-Partition -DiskNumber $which_disk -Size $i -GptType "{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}"
    Write-Progress -Activity "Creating Partitions" -Status "Current Partition: $count" -PercentComplete $count
    Get-Volume | Where-Object FileSystemType -eq "Unknown" | Format-Volume -FileSystem NTFS -NewFileSystemLabel ("PART" + [string]$count)
    Write-Progress -Activity "Formatting Partition (NTFS)" -Status "Current Partition: $count" -PercentComplete $count
    $count += 1
}

Stop-Transcript

"`r`nProcess Completed! Thank you for using AutoPart..."
