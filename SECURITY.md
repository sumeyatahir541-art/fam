# FAMI Rent Management - Security Guide

## Environment Variables Protection

✅ **DO**: Store sensitive keys in `.env.local` (local) and Vercel Environment Variables (production)
✅ **DO**: Add `.env.local` to `.gitignore`
✅ **DO**: Use Supabase anon key for frontend (it's public)

❌ **DON'T**: Commit `.env.local` to Git
❌ **DON'T**: Expose service key (server-only) on frontend
❌ **DON'T**: Log sensitive data in console

## Authentication Security

### Email/Password
- Minimum 6 characters enforced
- Supabase handles secure password storage (bcrypt)
- Enable email verification for production

### Session Management
- Supabase sessions are HttpOnly cookies
- Sessions auto-refresh within 1 hour
- Logout clears all sessions

## Role-Based Access Control (RBAC)

Four roles implemented:

| Role | Capabilities |
|------|---------------|
| **admin** | All operations + user management |
| **manager** | Shops, payments, reports |
| **payment_officer** | Payments only |
| **viewer** | Read-only access |

## Row-Level Security (RLS) Policies

All tables protected:
- `profiles`: Users can't modify others' data (except admins)
- `shops`: Only managers/admins can edit
- `payments`: Only payment officers+ can record
- `audit_logs`: All authenticated users can read

## Data Protection

### Encryption
✅ Supabase uses SSL/TLS for all connections
✅ Database uses encrypted storage at rest
✅ Backups are encrypted

### Audit Trail
✅ All actions logged to `audit_logs` table
✅ Includes user, timestamp, action, and changes
✅ Cannot be modified by users

## API Security

### Rate Limiting
- Supabase free tier: 50,000 API calls/month
- Consider rate limiting middleware in production

### CORS
- Configure allowed origins in Supabase > Settings > API
- Restrict to your domain(s)

## Deployment Security

### Vercel
✅ Automatic HTTPS
✅ DDoS protection
✅ WAF (Web Application Firewall)

### Supabase
✅ Database firewalls
✅ Connection pooling for protection
✅ Automated backups

## Best Practices

1. **Regular Password Changes**
   - Require users to change passwords quarterly
   - Enforce strong passwords (10+ chars, mix of types)

2. **Monitor Access**
   - Review audit logs monthly
   - Alert on suspicious patterns

3. **Backup Testing**
   - Test restore procedure monthly
   - Maintain off-site backups

4. **Update Dependencies**
   - Run `npm outdated` monthly
   - Update security patches immediately
   - Test updates before deploying

5. **Admin Accounts**
   - Use unique admin accounts per person
   - Enable 2FA if available
   - Audit admin actions monthly

## Incident Response

### Suspected Breach
1. Immediately reset admin passwords
2. Review audit_logs for unauthorized access
3. Enable enhanced logging
4. Contact Supabase support
5. Consider data backup/restore

### Data Loss
1. Restore from Supabase backup
2. Verify restore integrity
3. Update all users
4. Implement additional monitoring

## Compliance

### Data Privacy
- Collect only necessary data
- Allow users to export their data
- Implement data retention policies
- Document data processing

### Audit Requirements
- Maintain audit trail (automatically done)
- Retain logs for 90 days minimum
- Regular security audits
- Update security policies annually
