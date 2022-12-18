-- Run this after running xperience-training-13-base.sql

-- Drop user that bacpac can't use
USE [x13-medio-clinic]
GO
DROP USER [NT AUTHORITY\NETWORK SERVICE]
GO

-- Create user
USE [master]
GO
CREATE LOGIN [x13-medio-clinic] WITH PASSWORD=N'kLmX1Ay5FbKkmGlinNI3', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [x13-medio-clinic]
GO
CREATE USER [x13-medio-clinic] FOR LOGIN [x13-medio-clinic]
GO
USE [x13-medio-clinic]
GO
ALTER ROLE [db_owner] ADD MEMBER [x13-medio-clinic]
GO

-- Disable screen lock
UPDATE CMS_SettingsKey SET [KeyValue] = 'False', [KeyLastModified] = GETDATE()
  WHERE KeyName = 'CMSScreenLockEnabled'

-- Settings > System > Emails
UPDATE CMS_SettingsKey SET [KeyValue] = 'localhost:25', [KeyLastModified] = GETDATE()
  WHERE KeyName = 'CMSSMTPServer'

UPDATE CMS_SettingsKey SET [KeyValue] = 'False', [KeyLastModified] = GETDATE()
  WHERE KeyName = 'CMSUseSSL'

-- SMTP Servers (for email queue)
UPDATE CMS_SMTPServer SET ServerName = 'localhost:25', ServerUseSSL = '0', ServerEnabled = 1, ServerLastModified = GETDATE()

-- Redirect files (media, attachments, etc...) to disk or Azure storage.
-- UPDATE CMS_SettingsKey SET [KeyValue] = '1', [KeyLastModified] = GETDATE()
--   WHERE KeyName = 'CMSFilesLocationType'
