describe "how Set-Target resource responds" {
    Context 'when Ensure is set to Present and AutomaticPageFile is set' {   
        Mock -commandName Get-WmiObject -parameterFilter {$ClassName -like 'Win32_ComputerSystem'} -mockWith {
            new-module -ascustomobject -scriptblock {
                $AutomaticManagedPageFile = $true

                function Put()
                {
                    $Global:Win32_ComputerSystemPutValue = $this
                    $global:Win32_ComputerSystemPutValue = $true
                }
                Export-ModuleMember -Variable * -Function *            
            }
        }
                
        Mock -commandName Get-WmiObject -parameterFilter {$ClassName -like 'Win32_PageFileSetting'} -mockWith {
            new-module -ascustomobject -scriptblock {
                    $InitialSize = 0 
                    $MaximumSize = 0 
            
                    function Put()
                    {
                        $global:Win32_PageFileSettingPutValue = $this
                        $global:Win32_PageFileSettingPutWasCalled = $true
                    }
                    Export-ModuleMember -Variable * -Function *                        
            }
        }            


        Set-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Present'
                
        It 'should call put on Win32_ComputerSystem' {
            $global:Win32_ComputerSystemPutValue | should be ($true)
        }
        It 'should call put on Win32_PageFileSetting' {
            $global:Win32_PageFileSettingPutWasCalled | should be ($true)
        }
        It 'should set AutomaticManagedPageFile set to $false' {
            $global:Win32_ComputerSystemPutValue.AutomaticManagedPageFile | should be $false
        }        
        It 'should set Initial and Maximum size to 4 GB' {
            $global:Win32_PageFileSettingPutValue.InitialSize | should be (4gb/1mb)
            $global:Win32_PageFileSettingPutValue.MaximumSize | should be (4gb/1mb)
        }    
        
        Remove-Variable -Scope global -Name Win32_ComputerSystemPutWasCalled -ErrorAction SilentlyContinue
        Remove-Variable -Scope global -Name Win32_ComputerSystemPutValue -ErrorAction SilentlyContinue
        Remove-Variable -Scope global -Name Win32_PageFileSettingPutWasCalled -ErrorAction SilentlyContinue
        Remove-Variable -Scope global -Name Win32_PageFileSettingPutValue -ErrorAction SilentlyContinue
          
    }

}
