# G-DEIMP (Global Digital Engineering & Infrastructure Management Platform)

## 1) Enterprise-Scale Architecture (Microservice-Ready)

### 1.1 Core architectural style
- **Domain-Driven Design + Clean Architecture** for each bounded context.
- **Modular monolith first, microservice extraction ready**: every module ships with isolated domain/application/infrastructure/api packages and independent data contracts.
- **CQRS + MediatR** for command/query segregation and scalable write/read optimization.
- **Event-driven integration** for inter-module communication and async workflows.
- **Global deployment topology**:
  - Multi-region active-active for read paths.
  - Regional write ownership for latency-sensitive operations.
  - Cross-region replication and disaster recovery.

### 1.2 Logical platform map
- **Identity & Access Service**: SSO, OAuth2/OIDC, JWT, refresh tokens, MFA, policy engine.
- **Tenant & Org Service**: organizations, regions, branches, departments, legal entities.
- **Project Lifecycle Service**: tenders, bids, WBS/CBS, schedule, CPM, EVM, risks.
- **BIM & Drawing Service**: model versions, revisions, transmittals, check-in/out, markups, signatures.
- **MEP/HVAC Service**: load calcs, equipment schedules, submittals, RFIs, compliance matrix.
- **Site Execution Service**: DPR, snag/punch list, incidents, inspections, geo photos.
- **Procurement & Contracts Service**: vendors, POs, contracts, invoices, milestones.
- **Financial Control Service**: budgets, cost centers, forecasting, margin and overrun controls.
- **HR & Resource Service**: skills, attendance, timesheets, allocation, utilization.
- **Notification/Realtime Service**: SignalR hubs, in-app alerts, email/SMS orchestration.
- **Analytics & Intelligence Service**: KPI cubes, delay heatmaps, risk prediction, executive dashboards.
- **Audit & Compliance Service**: immutable logs, access trails, retention and legal hold.

### 1.3 Core runtime stack
- **Backend**: .NET 8, ASP.NET Core Web API, EF Core, MediatR, FluentValidation, AutoMapper, Serilog, Redis, Hangfire, Swagger.
- **Database**: SQL Server (RLS, temporal tables, partitioning, indexed views, always encrypted).
- **Frontend**: React + Vite + TypeScript + Tailwind + ShadCN + Redux Toolkit + React Query + D3 + TanStack Table + Framer Motion.
- **Infrastructure**: Docker, Kubernetes, NGINX/Azure App Gateway, Azure SQL MI/SQL Server, Azure Cache for Redis, Azure Monitor.

---

## 2) Multi-Tenant Global Data Isolation Model

### 2.1 Tenant hierarchy
`Organization -> Region -> Branch -> Department -> Project -> Discipline`

### 2.2 Isolation strategy
1. **Primary**: `TenantId` on every transactional row.
2. **SQL Server Row-Level Security** using tenant predicates.
3. **Optional schema-per-tenant** for regulated geographies.
4. **Encryption domain separation** per tenant (key vault managed keys).
5. **Cross-tenant operations** allowed only to Global Super Admin via elevated policies + audit trace.

### 2.3 RLS predicate pattern
- Session context set by API middleware: `sp_set_session_context('TenantId', @tenantId)`.
- Security policy applies on all tenant-bound tables with `FILTER PREDICATE` and `BLOCK PREDICATE`.

---

## 3) SQL Server Enterprise Schema (3NF+, audit-ready)

## 3.1 Reference tables
- `Tenants`, `Organizations`, `Regions`, `Branches`, `Departments`
- `Currencies`, `Countries`, `Disciplines`, `ProjectTypes`, `DocumentTypes`, `StatusCodes`

### 3.2 Security and IAM tables
- `Users (UserId, TenantId, Email, PasswordHash, MFAEnabled, IsActive, CreatedAt)`
- `Roles (RoleId, TenantId, Name, ScopeLevel)`
- `Permissions (PermissionId, Code, Description)`
- `RolePermissions (RoleId, PermissionId)`
- `UserRoles (UserId, RoleId, ProjectId nullable)`
- `PolicyRules (PolicyRuleId, Resource, Action, ConditionExpression)`
- `RefreshTokens`, `UserSessions`, `LoginAudit`

### 3.3 Delivery & engineering tables
- `Projects`, `ProjectDisciplines`, `WbsNodes`, `CbsNodes`, `ProjectTasks`
- `Schedules`, `TaskDependencies`, `EvmSnapshots`, `RiskRegisters`
- `Documents`, `DocumentRevisions`, `FileBlobs`, `Transmittals`, `ReviewWorkflows`
- `Rfis`, `Submittals`, `TechnicalClarifications`, `ClashIssues`
- `SiteDailyReports`, `SnagItems`, `SafetyIncidents`, `QualityInspections`

### 3.4 Commercial/finance tables
- `Vendors`, `VendorScores`, `Contracts`, `PurchaseOrders`, `PoLines`
- `Invoices`, `InvoiceLines`, `PaymentMilestones`, `TaxRules`, `BudgetAllocations`
- `CostCenters`, `ForecastEntries`, `RevenueRecognitions`, `FxRates`

### 3.5 Workforce tables
- `Employees`, `EmployeeSkills`, `Certifications`, `AttendanceLogs`
- `Timesheets`, `TimesheetEntries`, `LeaveRequests`, `ResourceAllocations`

### 3.6 Platform tables
- `Notifications`, `NotificationRecipients`, `ActivityLogs`, `SystemEvents`, `OutboxMessages`

### 3.7 SQL DDL skeleton (representative)
```sql
CREATE TABLE dbo.Projects (
    ProjectId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    OrganizationId UNIQUEIDENTIFIER NOT NULL,
    RegionId UNIQUEIDENTIFIER NOT NULL,
    DepartmentId UNIQUEIDENTIFIER NOT NULL,
    ProjectCode NVARCHAR(50) NOT NULL,
    Name NVARCHAR(300) NOT NULL,
    BaseCurrencyCode CHAR(3) NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProjectsHistory));

CREATE INDEX IX_Projects_Tenant_Region_Code
ON dbo.Projects (TenantId, RegionId, ProjectCode)
INCLUDE (Name, StartDate, EndDate);
```

### 3.8 Partitioning strategy
- Partition heavy tables by `TenantId + CreatedMonth` or `ProjectId + CreatedMonth` depending on access pattern:
  - `ActivityLogs`, `DocumentRevisions`, `TimesheetEntries`, `SiteDailyReports`, `Notifications`.

### 3.9 Indexed views for read-heavy analytics
- `vw_ProjectCostSummary`
- `vw_EarnedValueMetrics`
- `vw_ResourceUtilization`

### 3.10 Stored procedures for heavy operations
- `sp_GenerateProjectDashboardSnapshot`
- `sp_ComputeEvmForPeriod`
- `sp_BulkImportDrawingRevisions`
- `sp_CloseAccountingPeriod`

### 3.11 Data governance
- Soft delete via `IsDeleted` + filtered indexes.
- Temporal tables for regulated audit trails.
- Always Encrypted for PII/financial sensitive fields.
- CDC for downstream analytics pipelines.

---

## 4) Backend Solution Structure (.NET 8 + Clean Architecture)

```text
src/
  BuildingBlocks/
    Domain/
    Application/
    Infrastructure/
    Contracts/
    Observability/

  Services/
    Identity/
      Identity.API/
      Identity.Application/
      Identity.Domain/
      Identity.Infrastructure/

    Projects/
      Projects.API/
      Projects.Application/
      Projects.Domain/
      Projects.Infrastructure/

    BIM/
    MEP/
    SiteExecution/
    Procurement/
    Finance/
    HR/
    Notifications/
    Analytics/
    Compliance/

tests/
  Unit/
  Integration/
  Contract/
```

### 4.1 API layer essentials
- Versioned APIs (`/api/v1/...`).
- Middleware stack: correlation ID, tenant resolution, auth, RLS context, exception handling, request logging.
- OpenAPI + security schemes.
- Health checks: liveness/readiness/startup with dependency probing.

### 4.2 Application layer essentials
- CQRS command/query handlers via MediatR.
- FluentValidation pipeline behavior.
- Domain events + outbox pattern.
- DTO mapping through AutoMapper profiles.

### 4.3 Infrastructure layer essentials
- EF Core DbContext per module.
- Repositories + Unit of Work abstraction.
- Redis caching for hot reads and distributed locks.
- Hangfire for background workflows (snapshot generation, alerts, notification fanout).

---

## 5) Frontend Enterprise Structure (React + TS)

```text
apps/web/
  src/
    app/
      store/
      router/
      providers/
    modules/
      auth/
      dashboard/
      projects/
      bim/
      mep/
      site/
      procurement/
      finance/
      hr/
      analytics/
      admin/
    components/
      layout/
      tables/
      forms/
      charts/
      gantt/
      kanban/
      notifications/
    services/
      api-client/
      signalr/
      permissions/
    styles/
```

### 5.1 UX design principles
- Mega dashboard by role (CEO/CFO/Director/BIM/HR).
- Hierarchical sidebar mapped to tenant/project permissions.
- Data-dense grids (virtualization + server paging/filtering).
- Real-time toast + in-panel notifications via SignalR.
- Dark/light theme with strict accessibility standards.

---

## 6) Enterprise API Surface (Representative)

### 6.1 Identity & access
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/mfa/verify`
- `GET /api/v1/users/me/permissions`
- `POST /api/v1/admin/roles/{roleId}/permissions`

### 6.2 Tenant/project governance
- `GET /api/v1/tenants/{tenantId}/org-tree`
- `POST /api/v1/projects`
- `GET /api/v1/projects/{projectId}/dashboard`
- `POST /api/v1/projects/{projectId}/wbs`

### 6.3 BIM/documents
- `POST /api/v1/projects/{projectId}/documents/upload-init`
- `PUT /api/v1/projects/{projectId}/documents/{docId}/check-out`
- `PUT /api/v1/projects/{projectId}/documents/{docId}/check-in`
- `POST /api/v1/projects/{projectId}/documents/{docId}/revisions`
- `POST /api/v1/projects/{projectId}/transmittals`

### 6.4 Engineering/site/commercial/finance
- `POST /api/v1/projects/{projectId}/rfis`
- `POST /api/v1/projects/{projectId}/daily-reports`
- `POST /api/v1/contracts`
- `POST /api/v1/invoices`
- `GET /api/v1/projects/{projectId}/evm`
- `GET /api/v1/projects/{projectId}/cost-overrun-alerts`

### 6.5 Realtime endpoints
- SignalR hubs:
  - `/hubs/notifications`
  - `/hubs/project-live`
  - `/hubs/review-workflow`

---

## 7) Security Architecture (Government-grade)

- OAuth2/OIDC + JWT access token + rotating refresh tokens.
- MFA with TOTP/SMS/email (policy controlled).
- SSO adapters (Azure AD/Entra ID, SAML2 bridge).
- Hierarchical RBAC + policy-based authorization + project-scoped role assignments.
- Rate limiting (per IP, per user, per tenant).
- WAF + API gateway threat protection.
- End-to-end TLS 1.2+; HSTS; strict CORS/CSRF protections.
- Secure headers; XSS mitigation; input validation at API boundary.
- Database protections: RLS, TDE, always encrypted columns, key vault integration.
- Full audit: who/what/when/where (IP, user agent, session id, tenant id).
- GDPR readiness: consent log, data subject export, pseudonymization, retention jobs.

---

## 8) Deployment, DevOps, and Operations

### 8.1 Containers and orchestration
- Docker image per API and frontend app.
- Kubernetes namespaces by environment (`dev/stage/prod`).
- Ingress via NGINX/Azure App Gateway with WAF.
- HPA based on CPU, memory, queue depth, request latency.

### 8.2 CI/CD pipeline strategy (Azure DevOps/GitHub Actions)
1. Restore/build/test/static analysis.
2. Security scans (SAST, dependency, container image scan).
3. Publish artifacts and version tags.
4. Deploy to staging using blue/green.
5. Automated smoke/API/integration checks.
6. Manual approval gate for production.
7. Progressive rollout (canary) with auto rollback.

### 8.3 Environment topology
- **Prod**: multi-region, active-active read, active-passive write fallback.
- **Staging**: production-like with masked data.
- **DR**: warm standby with tested failover runbooks.

---

## 9) Performance and Scale Strategy

- Target: 250k users, 20k concurrent, 1000+ live projects.
- Scale reads with caching and read replicas.
- Use CQRS read models and indexed views for dashboards.
- Async heavy jobs to Hangfire queues and worker pools.
- Chunked/resumable upload for TB-scale drawings.
- CDN + object storage offload for static/document delivery.
- Backpressure and queue prioritization for peak project events.
- Performance budgets per API (P95/P99 latency and throughput SLOs).

---

## 10) Monitoring, Logging, and Compliance Observability

- Serilog structured logs with correlation IDs (`TenantId`, `ProjectId`, `UserId`).
- OpenTelemetry traces + metrics + logs.
- Centralized log store (Azure Monitor / Elastic).
- Dashboards:
  - Platform reliability: latency, errors, saturation.
  - Business operations: bids, RFIs, approvals, invoice aging.
  - Security posture: failed logins, suspicious access, policy violations.
- Alerts with severity routing (on-call, security ops, compliance team).
- Immutable audit archives with retention and legal hold controls.

---

## 11) Test and Validation Strategy

- **Unit tests (xUnit)**: domain logic, handlers, validators, policy evaluators.
- **Integration tests**: API + SQL Server + Redis + auth flows.
- **Contract tests**: inter-service API compatibility.
- **Performance tests**: load, stress, soak, spike.
- **Security tests**: OWASP ASVS checklist, penetration tests, token abuse scenarios.
- **Resilience tests**: chaos experiments (node failure, DB failover, queue delays).

---

## 12) Phased Delivery Roadmap

1. **Phase 1 (Foundation)**: identity, tenant hierarchy, project core, document core, audit baseline.
2. **Phase 2 (Execution)**: site ops, RFI/submittals, procurement/contracts.
3. **Phase 3 (Finance & HR)**: budgeting, invoices, forecasting, workforce allocation.
4. **Phase 4 (Intelligence)**: executive analytics, AI risk models, predictive alerts.
5. **Phase 5 (Global hardening)**: geo expansion, DR optimization, compliance certifications.

This blueprint delivers a **billion-dollar-class digital engineering command platform** with strict multi-tenant governance, deep project controls, BIM-native workflows, and enterprise-grade security/compliance.
