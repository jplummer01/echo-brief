locals {
  name_prefix    = "${var.prefix}${var.name}-${var.environment}"
  sha            = base64encode(sha256("${local.name_prefix}${var.environment}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  # api_command_line = "uvicorn main:app --host 0.0.0.0 --port 8000"
  api_command_line = "python3 -m gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000  --reload  --log-level debug"

  default_tags = {
    Region      = var.location
    Environment = var.environment
    Owner       = "AI-TEAM"
    Project     = "ECHO-BRIEF"
    Stage       = "ECHO-BRIEF-SERVICE"
    ManagedBy   = "TERRAFORM"
    CostCenter  = "AI-TEAM"
  }


  sed_command = var.os_type == "windows" ? (
    "powershell -Command \"(Get-Content '.\\frontend_app\\constants\\apiConstants.js') | ForEach-Object { $_ -replace 'BASE_NAME = \\\"BASE_NAME\\\"', 'BASE_NAME = \\\"${local.name_prefix}-echo-brief-backend-api-${random_string.unique.result}\\\"' } | Set-Content '.\\frontend_app\\constants\\apiConstants.js'\""
    ) : (
    "sed -i 's/BASE_NAME = \"BASE_NAME\"/BASE_NAME = \"${local.name_prefix}-echo-brief-backend-api-${random_string.unique.result}\"/g' frontend_app/constants/apiConstants.js"
  )



  # For Windows we use PowerShell commands to:
  #   - Check if frontend.zip exists and remove it if so.
  #   - Copy the entire '../frontend_app' directory to the current directory.
  #
  # For Linux/macOS we use rm and cp as before.
  copy_frontend_command = var.os_type == "windows" ? "powershell -Command \"if (Test-Path './frontend.zip') { Remove-Item './frontend.zip' -Force -Recurse }; if (Test-Path './frontend_app') { Remove-Item './frontend_app' -Force -Recurse }; Copy-Item -Path '../frontend_app' -Destination '.' -Recurse -Force\"" : "rm -rf frontend.zip frontend_app && cp -r ../frontend_app ."

}
