# G-DEIMP Implementation Preview (Enterprise Starter Pack)

This preview converts the architecture blueprint into **build-ready artifacts** your platform teams can start executing.

## 1) What this preview includes

- **Domain-aligned module map** with service boundaries and ownership.
- **Concrete backend solution skeleton** for .NET 8 + Clean Architecture + CQRS.
- **SQL Server schema starter** with core tables, FK patterns, tenant columns, temporal history, and RLS hooks.
- **API contract preview** (identity, projects, BIM documents, procurement, finance, HR, notifications).
- **Deployment preview** (Docker Compose baseline for local enterprise simulation).
- **Security and observability control matrix** with mandatory controls by layer.

---

## 2) Microservice-ready bounded contexts

| Context | Core Responsibility | Primary Aggregate Roots |
|---|---|---|
| Identity | Authentication, authorization, SSO, MFA | User, Role, Permission, Session |
| Tenant Governance | Org/Region/Branch/Department topology | Organization, Region, Branch, Department |
| Project Lifecycle | Tender, bid, WBS/CBS, schedule, EVM, risks | Project, WbsNode, Schedule, RiskRegister |
| BIM & Documents | Model lifecycle, revisions, transmittals, markups | Document, Revision, Transmittal, ReviewWorkflow |
| MEP/HVAC | Technical logs, equipment schedules, RFIs | EquipmentSchedule, Rfi, Submittal |
| Site Execution | DPR, snag/punch, incidents, quality | DailyReport, SnagItem, Inspection |
| Procurement | Vendor lifecycle, POs, contracts | Vendor, Contract, PurchaseOrder |
| Finance | Budgets, forecasts, invoices, margins | BudgetAllocation, Invoice, ForecastEntry |
| HR & Resources | Skills, attendance, timesheets, utilization | Employee, Timesheet, Allocation |
| Analytics & Intelligence | Executive KPIs, risk intelligence | KpiSnapshot, ForecastModel |
| Compliance & Audit | Immutable audit and regulatory controls | ActivityLog, ComplianceEvent |

---

## 3) Backend solution preview (.NET 8)

```text
src/
  BuildingBlocks/
    BuildingBlocks.Domain/
      Abstractions/
      Events/
      ValueObjects/
    BuildingBlocks.Application/
      Behaviors/
      Abstractions/
      Contracts/
    BuildingBlocks.Infrastructure/
      Persistence/
      Messaging/
      Caching/
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
  Load/
```

### 3.1 Mandatory cross-cutting pipeline
1. Correlation + tenant resolution middleware
2. Authentication/authorization middleware
3. Session context push (`TenantId`) to SQL Server
4. Global exception handler
5. Serilog request/response logging
6. MediatR pipeline:
   - Validation
   - Authorization behavior
   - Transaction behavior
   - Idempotency behavior

---

## 4) SQL schema starter (core)

> Full DDL is in `infra/sql/g-deimp-core-schema.sql`.

### 4.1 Core principles enforced
- 3NF+ normalized entities.
- `TenantId` on every transactional table.
- Soft delete (`IsDeleted`) + audit columns (`CreatedBy`, `CreatedAtUtc`, `ModifiedAtUtc`).
- Temporal history for regulated entities.
- RLS hooks for strict data isolation.

### 4.2 High-volume table partition candidates
- `DocumentRevisions`
- `TimesheetEntries`
- `ActivityLogs`
- `Notifications`
- `SiteDailyReports`

---

## 5) API preview (contract snapshot)

### 5.1 Identity
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/mfa/verify`
- `GET /api/v1/users/me/permissions`

### 5.2 Projects
- `POST /api/v1/projects`
- `GET /api/v1/projects/{projectId}`
- `GET /api/v1/projects/{projectId}/dashboard`
- `POST /api/v1/projects/{projectId}/wbs/nodes`

### 5.3 BIM/Documents
- `POST /api/v1/projects/{projectId}/documents/upload-init`
- `PUT /api/v1/projects/{projectId}/documents/{documentId}/check-out`
- `PUT /api/v1/projects/{projectId}/documents/{documentId}/check-in`
- `POST /api/v1/projects/{projectId}/documents/{documentId}/revisions`
- `POST /api/v1/projects/{projectId}/transmittals`

### 5.4 Procurement/Finance/HR
- `POST /api/v1/vendors`
- `POST /api/v1/contracts`
- `POST /api/v1/invoices`
- `GET /api/v1/projects/{projectId}/financial-summary`
- `POST /api/v1/timesheets`
- `GET /api/v1/resource-utilization`

### 5.5 Realtime hubs
- `/hubs/notifications`
- `/hubs/project-live`
- `/hubs/document-review`

---

## 6) Security control matrix (preview)

| Layer | Control | Implementation Preview |
|---|---|---|
| Edge | WAF + rate limits | App Gateway/NGINX policies per tenant and IP |
| API | OAuth2/OIDC + JWT | IdentityServer/Entra integration |
| API | Policy authorization | Dynamic permission matrix + project scope |
| Data | Row-level security | Security policy + tenant predicate function |
| Data | Encryption | TDE + Always Encrypted for PII/financial columns |
| Audit | Immutable logging | Activity log + SIEM forwarding + retention policies |

---

## 7) Frontend enterprise shell preview

- Role-based mega dashboard with module cards by permission.
- Collapsible multi-level sidebar (Org > Region > Branch > Projects).
- Global search (projects, documents, RFIs, contracts).
- Real-time notification center powered by SignalR.
- Data-heavy table framework (server pagination, column pinning, export).

---

## 8) Deployment preview (local enterprise simulation)

Use `docker compose -f infra/docker-compose.preview.yml up -d` to run:
- API gateway placeholder
- Identity API placeholder
- Projects API placeholder
- SQL Server
- Redis

---

## 9) What to build next (execution backlog)

1. Implement Identity + Tenant Governance services first.
2. Implement Project Lifecycle + BIM documents next.
3. Add Procurement + Finance + HR modules.
4. Introduce Analytics service and KPI materialization jobs.
5. Run load/security/chaos validation before production cutover.

This preview is intended to be the **program kickoff artifact** for architecture, platform, backend, frontend, QA, security, and DevOps streams.
