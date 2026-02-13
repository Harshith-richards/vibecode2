-- G-DEIMP Core Schema Preview (SQL Server)
-- Enterprise baseline: tenant isolation, temporal audit, soft delete, and extensible references.

CREATE TABLE dbo.Tenants (
    TenantId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantCode NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Organizations (
    OrganizationId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    CreatedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Organizations_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
);

CREATE TABLE dbo.Projects (
    ProjectId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    OrganizationId UNIQUEIDENTIFIER NOT NULL,
    ProjectCode NVARCHAR(50) NOT NULL,
    Name NVARCHAR(300) NOT NULL,
    BaseCurrencyCode CHAR(3) NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    CreatedBy UNIQUEIDENTIFIER NULL,
    CreatedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedAtUtc DATETIME2 NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
    CONSTRAINT FK_Projects_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT FK_Projects_Organizations FOREIGN KEY (OrganizationId) REFERENCES dbo.Organizations(OrganizationId),
    CONSTRAINT UQ_Projects_Tenant_ProjectCode UNIQUE (TenantId, ProjectCode)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProjectsHistory));

CREATE TABLE dbo.Documents (
    DocumentId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ProjectId UNIQUEIDENTIFIER NOT NULL,
    DocumentNo NVARCHAR(120) NOT NULL,
    Title NVARCHAR(500) NOT NULL,
    DisciplineCode NVARCHAR(50) NOT NULL,
    CurrentRevision NVARCHAR(20) NOT NULL,
    CheckOutUserId UNIQUEIDENTIFIER NULL,
    IsLocked BIT NOT NULL DEFAULT 0,
    IsDeleted BIT NOT NULL DEFAULT 0,
    CreatedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Documents_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT FK_Documents_Projects FOREIGN KEY (ProjectId) REFERENCES dbo.Projects(ProjectId),
    CONSTRAINT UQ_Documents_Tenant_Project_DocumentNo UNIQUE (TenantId, ProjectId, DocumentNo)
);

CREATE TABLE dbo.DocumentRevisions (
    RevisionId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    RevisionNo NVARCHAR(20) NOT NULL,
    FileUri NVARCHAR(1000) NOT NULL,
    HashSha256 NVARCHAR(64) NOT NULL,
    UploadedBy UNIQUEIDENTIFIER NOT NULL,
    UploadedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_DocumentRevisions_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT FK_DocumentRevisions_Documents FOREIGN KEY (DocumentId) REFERENCES dbo.Documents(DocumentId),
    CONSTRAINT UQ_DocumentRevisions_Document_RevisionNo UNIQUE (DocumentId, RevisionNo)
);

CREATE TABLE dbo.Roles (
    RoleId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(120) NOT NULL,
    ScopeLevel NVARCHAR(40) NOT NULL,
    CONSTRAINT FK_Roles_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT UQ_Roles_Tenant_Name UNIQUE (TenantId, Name)
);

CREATE TABLE dbo.Permissions (
    PermissionId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Code NVARCHAR(120) NOT NULL UNIQUE,
    Description NVARCHAR(400) NULL
);

CREATE TABLE dbo.RolePermissions (
    RoleId UNIQUEIDENTIFIER NOT NULL,
    PermissionId UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (RoleId, PermissionId),
    CONSTRAINT FK_RolePermissions_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(RoleId),
    CONSTRAINT FK_RolePermissions_Permissions FOREIGN KEY (PermissionId) REFERENCES dbo.Permissions(PermissionId)
);

CREATE TABLE dbo.ActivityLogs (
    ActivityLogId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ProjectId UNIQUEIDENTIFIER NULL,
    UserId UNIQUEIDENTIFIER NULL,
    Action NVARCHAR(120) NOT NULL,
    EntityName NVARCHAR(120) NOT NULL,
    EntityId NVARCHAR(120) NOT NULL,
    IpAddress NVARCHAR(64) NULL,
    UserAgent NVARCHAR(500) NULL,
    Metadata NVARCHAR(MAX) NULL,
    OccurredAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_Projects_Tenant_Org ON dbo.Projects(TenantId, OrganizationId) INCLUDE(Name, ProjectCode);
CREATE INDEX IX_Documents_Tenant_Project ON dbo.Documents(TenantId, ProjectId) INCLUDE(DocumentNo, CurrentRevision, IsLocked);
CREATE INDEX IX_DocumentRevisions_Tenant_Document ON dbo.DocumentRevisions(TenantId, DocumentId) INCLUDE(RevisionNo, UploadedAtUtc);
CREATE INDEX IX_ActivityLogs_Tenant_OccurredAt ON dbo.ActivityLogs(TenantId, OccurredAtUtc DESC);

-- Tenant predicate function (RLS hook)
CREATE FUNCTION dbo.fn_tenantPredicate(@TenantId UNIQUEIDENTIFIER)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_result
WHERE @TenantId = CAST(SESSION_CONTEXT(N'TenantId') AS UNIQUEIDENTIFIER);

-- Example RLS policy on Projects (repeat for tenant-bound tables)
CREATE SECURITY POLICY dbo.TenantRlsPolicy
ADD FILTER PREDICATE dbo.fn_tenantPredicate(TenantId) ON dbo.Projects,
ADD BLOCK PREDICATE dbo.fn_tenantPredicate(TenantId) ON dbo.Projects AFTER INSERT
WITH (STATE = ON);
