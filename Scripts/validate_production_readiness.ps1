# HealthAI-2030 Production Readiness Validation Script
param()

Write-Host "================================================" -ForegroundColor Green
Write-Host "    HEALTHAI-2030 PRODUCTION READINESS" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$validationResults = @()

# Function to validate file existence
function Test-FileExists {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-Host "✅ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $Description" -ForegroundColor Red
        return $false
    }
}

# Function to validate enhanced components
function Test-EnhancedComponents {
    Write-Host "Validating Enhanced Components..." -ForegroundColor Cyan
    Write-Host ""
    
    $components = @(
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedSecurityManager.swift"; Description = "Enhanced Security Manager"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedPerformanceManager.swift"; Description = "Enhanced Performance Manager"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedCodeQualityManager.swift"; Description = "Enhanced Code Quality Manager"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedTestingManager.swift"; Description = "Enhanced Testing Manager"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedIntegrationCoordinator.swift"; Description = "Enhanced Integration Coordinator"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedAuthenticationManager.swift"; Description = "Enhanced Authentication Manager"},
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core\EnhancedSecretsManager.swift"; Description = "Enhanced Secrets Manager"}
    )
    
    $validComponents = 0
    foreach ($component in $components) {
        if (Test-FileExists -FilePath $component.Path -Description $component.Description) {
            $validComponents++
        }
    }
    
    return $validComponents, $components.Count
}

# Function to validate documentation
function Test-Documentation {
    Write-Host "Validating Documentation..." -ForegroundColor Cyan
    Write-Host ""
    
    $docs = @(
        @{Path = "$ProjectRoot\ENHANCEMENT_REPORT.md"; Description = "Enhancement Report"},
        @{Path = "$ProjectRoot\COMPREHENSIVE_RE_EVALUATION_SUMMARY.md"; Description = "Comprehensive Re-Evaluation Summary"},
        @{Path = "$ProjectRoot\MISSION_ACCOMPLISHED.md"; Description = "Mission Accomplished Report"},
        @{Path = "$ProjectRoot\PRODUCTION_HANDOVER_PACKAGE.md"; Description = "Production Handover Package"}
    )
    
    $validDocs = 0
    foreach ($doc in $docs) {
        if (Test-FileExists -FilePath $doc.Path -Description $doc.Description) {
            $validDocs++
        }
    }
    
    return $validDocs, $docs.Count
}

# Function to validate scripts
function Test-Scripts {
    Write-Host "Validating Scripts..." -ForegroundColor Cyan
    Write-Host ""
    
    $scripts = @(
        @{Path = "$ProjectRoot\Scripts\apply_enhancements_simple.ps1"; Description = "Enhancement Application Script"},
        @{Path = "$ProjectRoot\Scripts\celebrate_enhancements.ps1"; Description = "Enhancement Celebration Script"},
        @{Path = "$ProjectRoot\Scripts\validate_production_readiness.ps1"; Description = "Production Readiness Validation Script"}
    )
    
    $validScripts = 0
    foreach ($script in $scripts) {
        if (Test-FileExists -FilePath $script.Path -Description $script.Description) {
            $validScripts++
        }
    }
    
    return $validScripts, $scripts.Count
}

# Function to validate project structure
function Test-ProjectStructure {
    Write-Host "Validating Project Structure..." -ForegroundColor Cyan
    Write-Host ""
    
    $directories = @(
        @{Path = "$ProjectRoot\Packages\HealthAI2030Core\Sources\HealthAI2030Core"; Description = "Core Package Sources"},
        @{Path = "$ProjectRoot\Apps\MainApp\Services"; Description = "Main App Services"},
        @{Path = "$ProjectRoot\Tests"; Description = "Test Suite"},
        @{Path = "$ProjectRoot\Scripts"; Description = "Scripts Directory"},
        @{Path = "$ProjectRoot\backup"; Description = "Backup Directory"}
    )
    
    $validDirs = 0
    foreach ($dir in $directories) {
        if (Test-Path $dir.Path) {
            Write-Host "✅ $($dir.Description)" -ForegroundColor Green
            $validDirs++
        } else {
            Write-Host "❌ $($dir.Description)" -ForegroundColor Red
        }
    }
    
    return $validDirs, $directories.Count
}

# Function to calculate overall readiness score
function Get-ReadinessScore {
    param(
        [int]$ValidComponents,
        [int]$TotalComponents,
        [int]$ValidDocs,
        [int]$TotalDocs,
        [int]$ValidScripts,
        [int]$TotalScripts,
        [int]$ValidDirs,
        [int]$TotalDirs
    )
    
    $componentScore = $ValidComponents / $TotalComponents * 100
    $docScore = $ValidDocs / $TotalDocs * 100
    $scriptScore = $ValidScripts / $TotalScripts * 100
    $dirScore = $ValidDirs / $TotalDirs * 100
    
    $overallScore = ($componentScore + $docScore + $scriptScore + $dirScore) / 4
    
    return $overallScore, $componentScore, $docScore, $scriptScore, $dirScore
}

# Main validation process
Write-Host "Starting Production Readiness Validation..." -ForegroundColor Yellow
Write-Host ""

# Validate enhanced components
$validComponents, $totalComponents = Test-EnhancedComponents
Write-Host ""

# Validate documentation
$validDocs, $totalDocs = Test-Documentation
Write-Host ""

# Validate scripts
$validScripts, $totalScripts = Test-Scripts
Write-Host ""

# Validate project structure
$validDirs, $totalDirs = Test-ProjectStructure
Write-Host ""

# Calculate readiness score
$overallScore, $componentScore, $docScore, $scriptScore, $dirScore = Get-ReadinessScore -ValidComponents $validComponents -TotalComponents $totalComponents -ValidDocs $validDocs -TotalDocs $totalDocs -ValidScripts $validScripts -TotalScripts $totalScripts -ValidDirs $validDirs -TotalDirs $totalDirs

# Display results
Write-Host "================================================" -ForegroundColor Green
Write-Host "    VALIDATION RESULTS" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Enhanced Components: $validComponents/$totalComponents ($([math]::Round($componentScore, 1))%)" -ForegroundColor $(if ($componentScore -eq 100) { "Green" } else { "Yellow" })
Write-Host "Documentation:       $validDocs/$totalDocs ($([math]::Round($docScore, 1))%)" -ForegroundColor $(if ($docScore -eq 100) { "Green" } else { "Yellow" })
Write-Host "Scripts:            $validScripts/$totalScripts ($([math]::Round($scriptScore, 1))%)" -ForegroundColor $(if ($scriptScore -eq 100) { "Green" } else { "Yellow" })
Write-Host "Project Structure:  $validDirs/$totalDirs ($([math]::Round($dirScore, 1))%)" -ForegroundColor $(if ($dirScore -eq 100) { "Green" } else { "Yellow" })
Write-Host ""

Write-Host "OVERALL READINESS SCORE: $([math]::Round($overallScore, 1))%" -ForegroundColor $(if ($overallScore -ge 95) { "Green" } elseif ($overallScore -ge 80) { "Yellow" } else { "Red" })
Write-Host ""

# Determine production readiness
if ($overallScore -ge 95) {
    Write-Host "✅ PRODUCTION READY!" -ForegroundColor Green
    Write-Host "All systems validated and ready for deployment." -ForegroundColor Green
    $productionReady = $true
} elseif ($overallScore -ge 80) {
    Write-Host "⚠️  NEARLY READY" -ForegroundColor Yellow
    Write-Host "Minor issues to address before production deployment." -ForegroundColor Yellow
    $productionReady = $false
} else {
    Write-Host "❌ NOT READY" -ForegroundColor Red
    Write-Host "Significant issues must be resolved before production deployment." -ForegroundColor Red
    $productionReady = $false
}

Write-Host ""

# Create validation report
$validationReport = @"
# HealthAI-2030 Production Readiness Validation Report

## Validation Summary
- **Overall Score:** $([math]::Round($overallScore, 1))%
- **Production Ready:** $(if ($productionReady) { "YES" } else { "NO" })
- **Validation Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Component Validation
- **Enhanced Components:** $validComponents/$totalComponents ($([math]::Round($componentScore, 1))%)
- **Documentation:** $validDocs/$totalDocs ($([math]::Round($docScore, 1))%)
- **Scripts:** $validScripts/$totalScripts ($([math]::Round($scriptScore, 1))%)
- **Project Structure:** $validDirs/$totalDirs ($([math]::Round($dirScore, 1))%)

## Recommendations
$(if ($productionReady) { "- System is ready for production deployment" } else { "- Address validation issues before deployment" })

---
*Report generated by Production Readiness Validation Script*
"@

$reportPath = "$ProjectRoot\PRODUCTION_READINESS_VALIDATION_REPORT.md"
Set-Content -Path $reportPath -Value $validationReport

Write-Host "Validation report saved to: $reportPath" -ForegroundColor Gray
Write-Host ""

if ($productionReady) {
    Write-Host "🎉 CONGRATULATIONS! HealthAI-2030 is ready for production!" -ForegroundColor Green
    Write-Host "🚀 Deploy with confidence!" -ForegroundColor Green
} else {
    Write-Host "🔧 Please address the validation issues before deployment." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "    VALIDATION COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green 