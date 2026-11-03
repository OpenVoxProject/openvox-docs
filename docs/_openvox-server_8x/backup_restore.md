---
layout: default
title: "Backing up and restoring OpenVox Server"
---

An OpenVox primary server holds one thing nothing else in your infrastructure can replace, the certificate authority (CA), next to configuration that is cheap to keep and data that the agents rebuild on their own. A good backup copies the first two every time and the third when you need it.

This page lists what lives on a primary server and why each item matters, how to back it up with `tar` and `pg_dump`, and how to put it back after a bad change, a lost CA directory, or a lost host.

The paths on this page are the package defaults, which `puppet config print --section server cadir ssldir confdir codedir` reports. Print them before you back up rather than trusting the tables. The layout is the same on OpenVox Server 8 and 9; on Debian and Ubuntu only the service environment files differ, as noted.

Two things to know before you start:

- A backup is only useful once it is off the host. Every recipe here writes to a directory on the primary server. Copy the result to your backup system straight afterwards.
- The archive contains private keys: the CA key, the server's host key, and the Hiera eyaml key if you use one. Create it with mode `0600`, keep it on encrypted storage, and treat access to it as access to every node the CA has signed.

## What a primary server holds

### Tier 0: irreplaceable

Lose any of these without a backup and there is no way to recover it. Losing the CA means re-enrolling every agent under a new one; losing a key means issuing a new key and replacing everything that depended on the old one, such as every eyaml-encrypted Hiera value.

| What | Where | Why it matters |
| ---- | ----- | -------------- |
| The certificate authority | `/etc/puppetlabs/puppetserver/ca/` (`cadir`), the whole directory: `ca_key.pem`, `root_key.pem`, `ca_crt.pem`, `ca_pub.pem`, `ca_crl.pem`, `serial`, `inventory.txt`, `infra_crl.pem`, `infra_inventory.txt`, `infra_serials`, `signed/`, `requests/` | Every agent trusts this CA. Without the key, no new node can be signed and no certificate revoked; without `inventory.txt` and `signed/`, the CA no longer knows the certificates it issued. The `infra_*` files drive the [infrastructure CRL](infrastructure_crl.html) and are empty placeholders until it is enabled. Owned by `puppet:puppet`, directory `0750`, files `0640`. |
| The server's own certificate and key | `/etc/puppetlabs/puppet/ssl/` (`ssldir`) | Re-issuable from the CA, but restoring it means no re-sign step and no change agents could notice. Also holds the server's copy of the CA bundle and the CRL. `puppet:puppet`. |
| OpenVoxDB's copy of the server certificate | `/etc/puppetlabs/puppetdb/ssl/` | Copies of the files above, made by `puppetdb ssl-setup`. Regenerable from `ssldir`, cheap to keep. `puppetdb:puppetdb`, `0700`. |
| Hiera eyaml keys | The paths that `pkcs7_private_key` and `pkcs7_public_key` name in each environment's `hiera.yaml`, for example `/etc/puppetlabs/puppet/eyaml/` | Without the private key, every encrypted Hiera value is gone and every secret in your data has to be rotated. The location is set by your control repository, not by the package, and the global `/etc/puppetlabs/puppet/hiera.yaml` usually does not mention it. |
| Code deploy key | Wherever r10k is told to find it: an `ssh` config entry, a `private_key` setting in `r10k.yaml`, or `/root/.ssh/` | Re-issuable on the Git server, but nothing deploys until it is. Often outside `/etc/puppetlabs/`, so a backup of that tree alone misses it. |
| Other site secrets | `csr_attributes.yaml` when it carries a pre-shared autosign key, webhook tokens, keys under `/etc/puppetlabs/bolt/` | Each is small and easy to forget. Back up `/etc/puppetlabs/` whole rather than listing them, and add the paths outside it that your site uses. |

### Tier 1: configuration

Small, cheap, and the thing you most often want to roll back after a change that did not work out.

| What | Where |
| ---- | ----- |
| OpenVox Server settings | `/etc/puppetlabs/puppetserver/conf.d/` (`puppetserver.conf`, `webserver.conf`, `web-routes.conf`, `auth.conf`, `ca.conf`, `global.conf`, `metrics.conf`, `versioned-code.conf` if static catalogs are on), `services.d/ca.cfg`, `logback.xml`, `request-logging.xml` |
| JVM arguments and service settings | `/etc/sysconfig/puppetserver` and `/etc/sysconfig/puppetdb` on Red Hat family systems; `/etc/default/puppetserver` and `/etc/default/puppetdb` on Debian and Ubuntu |
| Puppet settings | `/etc/puppetlabs/puppet/puppet.conf`, `autosign.conf`, `csr_attributes.yaml`, `hiera.yaml` (the global one), `puppetdb.conf`, `routes.yaml`, and `fileserver.conf` and `custom_trusted_oid_mapping.yaml` if present |
| OpenVoxDB settings | `/etc/puppetlabs/puppetdb/conf.d/` (`database.ini` holds the database password, `read_database.ini`, `jetty.ini`, `config.ini`, `auth.conf`), `bootstrap.cfg`, `logback.xml`, `request-logging.xml` |
| Code deployment | `/etc/puppetlabs/r10k/r10k.yaml`, plus whatever runs r10k for you: a systemd service and timer under `/etc/systemd/system/`, a webhook receiver's configuration, or a cron entry |
| Gems added to the server | The output of `puppetserver gem list`, and of `/opt/puppetlabs/puppet/bin/gem list` for the agent's Ruby, where r10k and the eyaml command line tool live. Keep the lists; the gems are reinstalled, not copied. |
| Package versions | `openvox-server`, `openvoxdb`, `openvoxdb-termini`, `openvox-agent`, and the PostgreSQL server package. A restore onto different versions is a migration, not a restore, so record them with the archive. |

Backing up `/etc/puppetlabs/` as one tree covers tiers 0 and 1 together, apart from the files outside it called out above, and does not go stale when a version adds a file. Decide what to put back at restore time instead.

If a Puppet module manages your primary server, part of tier 1 is desired state: the files the module writes come back on the next agent run whatever a restore put there. For those files, a rollback is a revert in your control repository or Hiera data followed by an agent run. The restore is for the files the module leaves alone.

### Tier 2: regenerable

Large, and either reproducible from somewhere else or rebuilt by the agents on their next run. Back these up when you cannot afford the time or the loss they imply, not by default.

| What | Where | What happens without it |
| ---- | ----- | ----------------------- |
| Deployed code | `/etc/puppetlabs/code/environments/`, one directory per environment | `r10k deploy environment --modules` rebuilds it from your Git server. Each environment's `.r10k-deploy.json` records the commit (`signature`) and the module versions that were deployed, so keep those files to be able to reproduce the exact state. Back up the tree itself only when your Git server shares the primary's blast radius. |
| r10k cache | `/var/cache/r10k/` | Re-fetched on the next deploy. |
| OpenVoxDB data | The `puppetdb` database in PostgreSQL, dumped with `pg_dump` | Facts and catalogs come back on each agent's next run. Reports, resource events, and exported resources do not. Sites that rely on exported resources, on report history, or on tools that read OpenVoxDB want this tier. The `puppetdb` role owns every table and `puppetdb-read` is the read-only connection's role; never copy the database as files while PostgreSQL runs. |
| Server runtime data | `/opt/puppetlabs/server/data/puppetserver/` | The node cache (`yaml/`) and the JRuby gem directory regenerate; the file bucket (`bucket/`) matters only if your site uses it, and reports stored there only if you do not send them to OpenVoxDB. If you use static catalogs, the `code_id` and `code_content` scripts under `scripts/` are yours and belong in the backup. |

### What is not here

- **Compilers** hold no unique state: their certificates come from the CA, their code from r10k, their configuration from your control repository. A lost compiler is rebuilt and re-enrolled following [Scaling OpenVox Server with compilers](scaling_puppet_server.html); it is not restored.
- **Agents** hold nothing worth keeping. A lost agent re-enrolls.
- **PostgreSQL's data directory** is not copied as files. It is only consistent when PostgreSQL is stopped, it is tied to the PostgreSQL major version, and `pg_dump` gives you a smaller, portable copy of the same thing.
- **Puppet Enterprise's other databases** (classifier, RBAC, orchestrator, activity) do not exist on OpenVox. If you are migrating from PE, there is nothing to carry over for them.
- **OpenVoxDB's archive export** (`/pdb/admin/v1/archive`) is not a backup format. It produced an archive holding only metadata on OpenVoxDB 8.17.0 and 9.0.0. Use `pg_dump`.

## Backing up

The commands below run as root on the primary server and produce a timestamped directory under `/var/backups/openvox`. They do not stop any service: the CA directory changes only when a certificate is signed or revoked, and `pg_dump` produces a consistent snapshot on its own.

Run the steps as one script that starts with `set -euo pipefail`, so that a failing step stops the run instead of leaving a gap in the archive.

### Record versions and state

```console
set -euo pipefail
backup=/var/backups/openvox/$(hostname -f)-$(date +%Y%m%dT%H%M%S)
install -d -m 0700 "$backup"
rpm -q openvox-server openvoxdb openvoxdb-termini openvox-agent postgresql-server > "$backup/versions.txt" || true
puppetserver gem list > "$backup/puppetserver-gems.txt"
/opt/puppetlabs/puppet/bin/gem list > "$backup/agent-gems.txt"
sha256sum /etc/puppetlabs/puppetserver/ca/{serial,ca_crl.pem,inventory.txt} > "$backup/ca-state-before"
```

On Debian and Ubuntu, use `dpkg-query -W openvox-server openvoxdb openvoxdb-termini openvox-agent postgresql` for the versions. A package that is not installed, such as `postgresql-server` on a primary whose database is on another host, is noted in `versions.txt` rather than stopping the script.

### Back up tiers 0 and 1

Archive `/etc/puppetlabs/` without the deployed code, together with the service settings files and the paths outside `/etc/puppetlabs/` that your site uses. The example adds root's SSH directory for the deploy key, a systemd unit pair that runs r10k, and the static catalog scripts; replace them with yours and drop the ones you do not have.

Without the scripts, a server whose restored `conf.d` turns static catalogs on compiles no catalog at all.

```console
tar --exclude=/etc/puppetlabs/code -czf "$backup/etc-puppetlabs.tar.gz" \
  /etc/puppetlabs \
  /etc/sysconfig/puppetserver /etc/sysconfig/puppetdb \
  /root/.ssh /etc/systemd/system/r10k-deploy.* \
  /opt/puppetlabs/server/data/puppetserver/scripts
```

On Debian and Ubuntu, the service settings files are `/etc/default/puppetserver` and `/etc/default/puppetdb`.

Record what code was deployed, which is enough to reproduce the environments with r10k:

```console
for d in /etc/puppetlabs/code/environments/*/; do
  [ -f "$d/.r10k-deploy.json" ] || continue
  cp "$d/.r10k-deploy.json" "$backup/r10k-deploy-$(basename "$d").json"
done
```

### Back up OpenVoxDB

Dump the database with the connection OpenVoxDB itself uses, read from `database.ini`. This works the same whether PostgreSQL is on the primary or on another host, and needs no shell on the database server. `pg_dump` comes with the `postgresql` package on Red Hat family systems and `postgresql-client` on Debian and Ubuntu; a primary with a local PostgreSQL already has it.

```console
ini=/etc/puppetlabs/puppetdb/conf.d/database.ini
# subname has the form //HOST:PORT/DATABASE
subname=$(sed -n 's/^subname *= *//p' "$ini")
user=$(sed -n 's/^username *= *//p' "$ini")
export PGPASSWORD=$(sed -n 's/^password *= *//p' "$ini")
host=${subname#//}; host=${host%%[:/]*}
port=$(echo "$subname" | sed -n 's#//[^:/]*:\([0-9]*\)/.*#\1#p')
port=${port:-5432}
db=${subname##*/}
pg_dump -h "$host" -p "$port" -U "$user" -d "$db" \
  -Fd -Z3 -j4 -f "$backup/openvoxdb"
unset PGPASSWORD
```

The directory format (`-Fd`) with compression (`-Z3`) and four parallel jobs (`-j4`) is what `pg_restore -j4` reads back fastest. The `puppetdb` role owns every table, so it can dump and restore the database without superuser rights; only dropping and recreating the `public` schema before a restore needs the `postgres` user.

### Close the archive

Lock the directory down, then confirm the CA did not change while you worked:

```console
chmod -R go-rwx "$backup"
sha256sum -c --quiet "$backup/ca-state-before"
rm "$backup/ca-state-before"
du -sh "$backup"
```

If `sha256sum` reports a file as `FAILED`, a certificate was signed or revoked during the backup, and the script stops there; run it again. Then copy the directory off the host.

### How often

Take a backup before every upgrade and after every batch of certificate signings or revocations, and on a schedule that matches how often your fleet changes.

A CA restored from a backup does not know the certificates signed, or revoked, after that backup was taken; the smaller that set, the simpler the recovery. Tier 2 is worth including on the schedule only if your site depends on report history or exported resources.

## Restoring

Every procedure below assumes the host being restored has the same certname as the one the backup came from, and the same package versions as `versions.txt` records. Changing either is a migration, which this page does not cover. The procedures stop OpenVox Server, and where they say so OpenVoxDB, for their duration; agents retry on their next scheduled run and need no attention.

### Roll back configuration on the same host

A change to `conf.d`, JVM settings, or `puppet.conf` did not work out, and you want yesterday's files back.

1. Stop the agent and the services, so that no scheduled agent run lands in the middle of the extract:

   ```console
   systemctl stop puppet puppetserver puppetdb
   ```

2. Extract the archive over the live tree. Owners and modes come back with the files, since the archive was made as root:

   ```console
   tar -C / -xzpf "$backup/etc-puppetlabs.tar.gz" \
     --exclude=etc/puppetlabs/puppetserver/ca \
     --exclude=etc/puppetlabs/puppet/ssl \
     --exclude=etc/puppetlabs/puppetdb/ssl
   ```

   The excludes leave the CA and the certificates alone, so a host enrolled since the backup keeps working. The rebuild procedures below use the full archive.

   To put back only part of the tree, name the paths after the archive, for example `etc/puppetlabs/puppetserver/conf.d`. Leave out any `*.rpmnew` or `*.dpkg-dist` the archive holds. Files added since the backup stay in place; remove any you do not want yourself.

3. Start the services, confirm they answer, and only then start the agent:

   ```console
   systemctl start puppetserver puppetdb
   curl -sk https://localhost:8140/status/v1/simple
   curl -s http://localhost:8080/status/v1/simple
   systemctl start puppet
   ```

   `systemctl start` returns once the services are up, which takes a minute or two; each status endpoint then prints `running`.

4. Run the agent on the primary server once. If a module manages the server, this is where its files take over again.

The outcome: the server runs with the restored settings and every agent's next run exits 0.

### Restore a lost CA directory

The CA directory is gone or damaged but the fleet still has its certificates. Because the CA certificate in the backup is the one every agent already trusts, nothing on the agents changes.

1. Stop the agent on the primary server, then OpenVox Server. The agent goes first so that nothing that manages the server runs while the CA is missing: a module that sets up the CA when `ca_crt.pem` is absent will try to, and the failed run (`puppetserver ca setup` refuses while the server's own certificate exists) is one more thing to sort out.

   The `puppet` unit is the agent and `puppetserver` is the server:

   ```console
   systemctl stop puppet
   systemctl stop puppetserver
   ```

2. Extract the CA directory from the archive:

   ```console
   tar -C / -xzpf "$backup/etc-puppetlabs.tar.gz" \
     etc/puppetlabs/puppetserver/ca
   ```

3. Find the hosts enrolled after the backup was taken. Their certificates are valid as far as the agents are concerned, but the restored CA does not know them, so it cannot revoke or renew them. The server cannot list them for you, because the record that would show them is the one you lost.

   OpenVoxDB can, and step 1 left it running: every node that has checked in is there, so compare its node list with the archive's inventory. This uses `jq`, which needs to be installed first, and OpenVoxDB's plain-text port, which listens on `localhost:8080` unless `jetty.ini` moved it:

   ```console
   tar -xzOf "$backup/etc-puppetlabs.tar.gz" \
     etc/puppetlabs/puppetserver/ca/inventory.txt \
     | sed -n 's|.*/CN=||p' | sort -u > /tmp/ca-known
   curl -s http://localhost:8080/pdb/query/v4/nodes \
     | jq -r '.[].certname' | sort | comm -13 /tmp/ca-known -
   ```

   Each host the second command prints needs a new certificate; step 5 covers that. Hosts that have not checked in since the backup are not on the list; add them from your provisioning records.

   The restored revocation list is the backup's as well, so a certificate revoked since then is valid again. After step 4, revoke it once more with `puppetserver ca revoke --certname <name>`.

4. Start the services:

   ```console
   systemctl start puppetserver puppet
   ```

5. Re-enroll each host from step 3. Do not use `puppetserver ca clean` for this: the restored CA counts serial numbers on from where the backup left them, so the serials of certificates signed since the backup are issued again, and a serial that `ca clean` placed on the revocation list makes a later certificate revoked from the start.

   If a copy of the certificate survived in the CA directory, delete it by hand instead:

   ```console
   rm -f /etc/puppetlabs/puppetserver/ca/signed/<name>.pem
   ```

   On the agent, discard its certificate and request a new one:

   ```console
   puppet ssl clean
   puppet ssl bootstrap
   ```

   Unless you use autosigning, sign the request on the CA server:

   ```console
   puppetserver ca sign --certname <name>
   ```

   [Regenerate an agent certificate](certificate_renewal.html#regenerate-an-agent-certificate) has the details, including what to do for a compiler.

The outcome: existing agents run unchanged, and the hosts you re-enrolled hold certificates the CA knows.

### Rebuild the primary server on a new host

The host is lost. You have the backup, and the replacement host has the same certname and the same DNS name or IP address the agents use.

1. Install the agent and OpenVox Server packages at the versions `versions.txt` records, following [Install OpenVox Server](install_from_packages.html), up to and including the first start of the service. Do not sign anything or run the agent. The CA and host certificate the server creates on its first start are discarded in the next step.

   Pin the versions when you install, for example `dnf install openvox-agent-9.2.1 openvox-server-9.1.0` or `apt install openvox-agent=9.2.1-1+ubuntu24.04 openvox-server=9.1.0-1+ubuntu24.04`.

2. Stop the service and extract the archive, holding back the two files that point the server at OpenVoxDB, and take the three OpenVoxDB settings out of `puppet.conf` for now. With them in place and no OpenVoxDB yet, the server would not start. The rest of `puppet.conf` (the certname, the server name, the environment) is what the next steps need:

   ```console
   systemctl stop puppetserver
   tar -C / -xzpf "$backup/etc-puppetlabs.tar.gz" \
     --exclude=etc/puppetlabs/puppet/puppetdb.conf \
     --exclude=etc/puppetlabs/puppet/routes.yaml
   puppet config delete storeconfigs --section server
   puppet config delete storeconfigs_backend --section server
   puppet config delete reports --section server
   ```

   If your `puppet.conf` keeps these settings in another section, name that section instead.

3. Reinstall any gems from `puppetserver-gems.txt` and `agent-gems.txt` that the package does not provide, with `puppetserver gem install` and `/opt/puppetlabs/puppet/bin/gem install` respectively.

4. Start OpenVox Server and deploy the code. `r10k.yaml` and the deploy key came back with the archive; r10k itself is a gem in the agent's Ruby and is not on root's path:

   ```console
   systemctl start puppetserver
   /opt/puppetlabs/puppet/bin/r10k deploy environment --modules
   ```

   To deploy exactly what was deployed before, check out the commit each `r10k-deploy-<environment>.json` names as `signature`.

5. Run the agent on the primary server once. If your control repository installs OpenVoxDB and PostgreSQL, this run creates the empty database and the `puppetdb` role, which the restore of the database needs. If you install them another way, do that now. Either way, make sure `openvoxdb-termini` is installed at the recorded version afterwards.

6. Put back the two files held back in step 2 and the archive's `puppet.conf`, which brings the three settings back, then restart the server:

   ```console
   tar -C / -xzpf "$backup/etc-puppetlabs.tar.gz" \
     etc/puppetlabs/puppet/puppet.conf \
     etc/puppetlabs/puppet/puppetdb.conf \
     etc/puppetlabs/puppet/routes.yaml
   systemctl restart puppetserver
   ```

7. Restore OpenVoxDB from the dump, following [Restore OpenVoxDB](#restore-openvoxdb) below.

8. Run the agent once more, then check that an agent elsewhere in the fleet completes a run without a certificate warning.

The outcome: agents see the same CA, the same server certificate, and the same certname, and notice nothing beyond the outage.

### Restore OpenVoxDB

Use this after a rebuild, or when the database is lost or corrupt and you want the reports and exported resources back rather than waiting for the agents to repopulate facts and catalogs.

OpenVoxDB's database role owns every object in the database, so it can restore without superuser rights. The one privileged step is resetting the schema, which the `postgres` user does. `pg_restore --clean` is not an alternative: it fails on the partitioned `resource_events_*` tables. The database and the role must exist under the names `database.ini` gives, which is where the commands read them.

```console
systemctl stop puppetdb
ini=/etc/puppetlabs/puppetdb/conf.d/database.ini
subname=$(sed -n 's/^subname *= *//p' "$ini")
user=$(sed -n 's/^username *= *//p' "$ini")
host=${subname#//}; host=${host%%[:/]*}
port=$(echo "$subname" | sed -n 's#//[^:/]*:\([0-9]*\)/.*#\1#p')
port=${port:-5432}
db=${subname##*/}
sudo -u postgres psql -q -d "$db" <<SQL
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
ALTER SCHEMA public OWNER TO pg_database_owner;
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO "$user";
SQL
export PGPASSWORD=$(sed -n 's/^password *= *//p' "$ini")
pg_restore -h "$host" -p "$port" -U "$user" -d "$db" -j4 "$backup/openvoxdb"
unset PGPASSWORD
systemctl start puppetdb
```

The `DROP SCHEMA` prints notices about the objects it cascades to; that is the old schema going.

On PostgreSQL 14 and earlier `public` is owned by `postgres`, so leave the `ALTER SCHEMA` line out. With PostgreSQL on another host, run the schema reset through an administrative connection there; `pg_restore` needs no shell on the database host. OpenVoxDB starts, finds the schema it expects, and the reports are there.

### A CA lost with no backup

A CA directory that is gone with no copy cannot be restored. The agents still trust the old CA certificate, but nothing can sign new certificates under it, revoke old ones, or renew them before they expire.

The way forward is to create a new CA and re-enroll every node, following [Regenerate all certificates in an OpenVox deployment](/openvox/latest/ssl_regenerate_certificates.html). Expect an outage on every agent until it has been through that process, and plan the rollout rather than letting it happen on the agents' schedule.

## Automating backups

The recipes above are plain `tar` and `pg_dump`, so any backup system can run them from a cron entry or systemd timer.

## Related pages

- [Upgrading OpenVox Server](upgrade_minor.html): take a backup first.
- [Renewing and regenerating certificates](certificate_renewal.html)
- [Infrastructure CRL](infrastructure_crl.html)
- [Scaling OpenVox Server with compilers](scaling_puppet_server.html)
- [Configuring OpenVoxDB](/openvoxdb/latest/configure.html): where `database.ini` is documented.
