Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Function to Create Filter Configuration
Function New-SPFilterConfig {
    param(
        [string]$ColumnName,
        [string]$ColumnType,
        [object]$MinValue,
        [object]$MaxValue,
        [string]$Operator,
        [object]$SingleValue
    )
    
    return @{
        ColumnName = $ColumnName
        ColumnType = $ColumnType
        MinValue = $MinValue
        MaxValue = $MaxValue
        Operator = $Operator
        SingleValue = $SingleValue
    }
}

#Function to Download Filtered Files with Dynamic Filtering
Function Download-SPDocumentLibraryWithDynamicFilter($SiteURL, $LibraryName, $DownloadPath, $FilterConfig)
{
    Try {
        #Get the Web
        $Web = Get-SPWeb $SiteURL
 
        #Delete any existing files and folders in the download location
        If (Test-Path $DownloadPath) { 
            Write-host -f Yellow "Cleaning download directory: $DownloadPath"
            Get-ChildItem -Path $DownloadPath -Recurse | ForEach-object { 
                Remove-item -Recurse -path $_.FullName -Force 
            } 
        }
 
        #Get the document Library
        $Library = $Web.Lists[$LibraryName]
        Write-host -f Magenta "Downloading Document Library: $($Library.Title)"
        Write-host -f Cyan "Filter Configuration:"
        Write-host -f Cyan "  Column: $($FilterConfig.ColumnName)"
        Write-host -f Cyan "  Type: $($FilterConfig.ColumnType)"
        Write-host -f Cyan "  Operator: $($FilterConfig.Operator)"
        
        if ($FilterConfig.Operator -eq "Between") {
            Write-host -f Cyan "  Range: $($FilterConfig.MinValue) to $($FilterConfig.MaxValue)"
        } else {
            Write-host -f Cyan "  Value: $($FilterConfig.SingleValue)"
        }
        
        #Build CAML query based on filter configuration
        $Query = New-Object Microsoft.SharePoint.SPQuery
        $CamlWhere = Build-CAMLFilter -FilterConfig $FilterConfig
        $Query.Query = $CamlWhere
        
        Write-host -f Gray "CAML Query: $($Query.Query)"
        
        #Get filtered items
        $FilteredItems = $Library.GetItems($Query)
        Write-host -f Yellow "Found $($FilteredItems.Count) items matching the filter"
        
        if ($FilteredItems.Count -eq 0) {
            Write-host -f Red "No items found matching the specified filter!"
            return
        }
        
        #Download each filtered item
        $DownloadCount = 0
        ForEach ($Item in $FilteredItems)
        {
            if ($Item.File -ne $null)
            {
                $File = $Item.File
                $ColumnValue = $Item[$FilterConfig.ColumnName]
                
                if ($ColumnValue -ne $null) {
                    #Create folder with column value
                    $ValueFolderPath = Join-Path $DownloadPath $ColumnValue.ToString()
                    If (!(Test-Path -path $ValueFolderPath))
                    {   
                        $ValueFolder = New-Item $ValueFolderPath -type directory -Force
                        Write-host -f Yellow "Created folder: $ColumnValue"
                    }
                    
                    #Download the file to the value folder
                    $Data = $File.OpenBinary()
                    $FilePath = Join-Path $ValueFolderPath $File.Name
                    [System.IO.File]::WriteAllBytes($FilePath, $data)
                    Write-host -f Green "Downloaded '$($File.Name)' to folder: $ColumnValue"
                    $DownloadCount++
                }
                else {
                    Write-host -f Red "File '$($File.Name)' has no value for column '$($FilterConfig.ColumnName)', skipping..."
                }
            }
        }
 
        Write-host -f Green "*** Download Completed ***"
        Write-host -f Green "Downloaded $DownloadCount files organized in folders by $($FilterConfig.ColumnName) value"
    }
    Catch {
        Write-host -f Red "Error Downloading Document Library:" $_.Exception.Message
        Write-host -f Red "Stack Trace: " $_.Exception.StackTrace
    }
    Finally {
        if ($Web -ne $null) {
            $Web.Dispose()
        }
    }
}

#Function to Build CAML Filter Based on Configuration
Function Build-CAMLFilter($FilterConfig) {
    $ColumnType = Get-ColumnTypeForCAML -TypeName $FilterConfig.ColumnType
    
    switch ($FilterConfig.Operator) {
        "Between" {
            return @"
            <Where>
                <And>
                    <Geq>
                        <FieldRef Name='$($FilterConfig.ColumnName)' />
                        <Value Type='$ColumnType'>$($FilterConfig.MinValue)</Value>
                    </Geq>
                    <Leq>
                        <FieldRef Name='$($FilterConfig.ColumnName)' />
                        <Value Type='$ColumnType'>$($FilterConfig.MaxValue)</Value>
                    </Leq>
                </And>
            </Where>
"@
        }
        "Equals" {
            return @"
            <Where>
                <Eq>
                    <FieldRef Name='$($FilterConfig.ColumnName)' />
                    <Value Type='$ColumnType'>$($FilterConfig.SingleValue)</Value>
                </Eq>
            </Where>
"@
        }
        "GreaterThan" {
            return @"
            <Where>
                <Gt>
                    <FieldRef Name='$($FilterConfig.ColumnName)' />
                    <Value Type='$ColumnType'>$($FilterConfig.SingleValue)</Value>
                </Gt>
            </Where>
"@
        }
        "LessThan" {
            return @"
            <Where>
                <Lt>
                    <FieldRef Name='$($FilterConfig.ColumnName)' />
                    <Value Type='$ColumnType'>$($FilterConfig.SingleValue)</Value>
                </Lt>
            </Where>
"@
        }
        "Contains" {
            return @"
            <Where>
                <Contains>
                    <FieldRef Name='$($FilterConfig.ColumnName)' />
                    <Value Type='$ColumnType'>$($FilterConfig.SingleValue)</Value>
                </Contains>
            </Where>
"@
        }
        "StartsWith" {
            return @"
            <Where>
                <BeginsWith>
                    <FieldRef Name='$($FilterConfig.ColumnName)' />
                    <Value Type='$ColumnType'>$($FilterConfig.SingleValue)</Value>
                </BeginsWith>
            </Where>
"@
        }
        default {
            throw "Unsupported operator: $($FilterConfig.Operator)"
        }
    }
}

#Function to Map Column Types to CAML Types
Function Get-ColumnTypeForCAML($TypeName) {
    $typeMapping = @{
        "Text" = "Text"
        "Number" = "Number"
        "DateTime" = "DateTime"
        "Boolean" = "Boolean"
        "Choice" = "Text"
        "MultiChoice" = "Text"
        "User" = "User"
        "Lookup" = "Lookup"
        "Integer" = "Integer"
        "Currency" = "Currency"
    }
    
    if ($typeMapping.ContainsKey($TypeName)) {
        return $typeMapping[$TypeName]
    } else {
        Write-host -f Yellow "Unknown column type '$TypeName', defaulting to 'Text'"
        return "Text"
    }
}

#Function to Test Filter Configuration
Function Test-FilterConfiguration($SiteURL, $LibraryName, $FilterConfig) {
    Try {
        $Web = Get-SPWeb $SiteURL
        $Library = $Web.Lists[$LibraryName]
        $Field = $Library.Fields[$FilterConfig.ColumnName]
        
        if ($Field -eq $null) {
            Write-host -f Red "Error: Column '$($FilterConfig.ColumnName)' not found in library '$LibraryName'"
            Write-host -f Yellow "Available columns:"
            $Library.Fields | Where-Object { $_.Hidden -eq $false -and $_.ReadOnlyField -eq $false } | 
                            Select-Object Title, InternalName, Type | 
                            Format-Table -AutoSize
            return $false
        }
        
        Write-host -f Green "Column found: $($Field.Title) (Type: $($Field.Type), InternalName: $($Field.InternalName))"
        return $true
    }
    Catch {
        Write-host -f Red "Error testing configuration: $($_.Exception.Message)"
        return $false
    }
    Finally {
        if ($Web -ne $null) { $Web.Dispose() }
    }
}

# Pre-defined Filter Configurations - Choose one of these:

# Example 1: Original clid filter (Number between 20-500)
$Filter1 = New-SPFilterConfig -ColumnName "KnowledgeID" -ColumnType "Number" -MinValue 627 -MaxValue 763 -Operator "Between"

# Example 2: Date range filter
#$Filter2 = New-SPFilterConfig -ColumnName "Created" -ColumnType "DateTime" -MinValue "2024-01-01" -MaxValue "2024-12-31" -Operator "Between"

# Example 3: Single value equality filter (Text)
#$Filter3 = New-SPFilterConfig -ColumnName "Category" -ColumnType "Text" -Operator "Equals" -SingleValue "Project Documents"

# Example 4: Greater than filter
#$Filter4 = New-SPFilterConfig -ColumnName "FileSize" -ColumnType "Number" -Operator "GreaterThan" -SingleValue 1048576

# Example 5: Contains text filter
#$Filter5 = New-SPFilterConfig -ColumnName "Title" -ColumnType "Text" -Operator "Contains" -SingleValue "Report"

# Example 6: Less than filter
#$Filter6 = New-SPFilterConfig -ColumnName "FileSize" -ColumnType "Number" -Operator "LessThan" -SingleValue 1048576

# Example 7: Starts with filter
#$Filter7 = New-SPFilterConfig -ColumnName "Title" -ColumnType "Text" -Operator "StartsWith" -SingleValue "FY2024"

# Main execution
$SiteURL = "http://mysharepointsite.com/"
$LibraryName ="Trn_UploadDocument"
$DownloadPath ="\\sf01\download\path"

# CHOOSE YOUR FILTER CONFIGURATION HERE:
$SelectedFilter = $Filter1  # Change this to $Filter1, $Filter2, etc.

# Or create a custom filter dynamically:
# $SelectedFilter = New-SPFilterConfig -ColumnName "YourColumnName" -ColumnType "Text" -Operator "Equals" -SingleValue "YourValue"

Write-host -f Magenta "Testing filter configuration..."
$ConfigValid = Test-FilterConfiguration -SiteURL $SiteURL -LibraryName $LibraryName -FilterConfig $SelectedFilter

if ($ConfigValid) {
    # Call the Function with dynamic filter
    Download-SPDocumentLibraryWithDynamicFilter -SiteURL $SiteURL -LibraryName $LibraryName -DownloadPath $DownloadPath -FilterConfig $SelectedFilter
} else {
    Write-host -f Red "Configuration test failed. Please adjust your filter settings."
}