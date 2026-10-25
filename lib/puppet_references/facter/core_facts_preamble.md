<!-- markdownlint-disable MD041 MD051 -->
<!-- Prepended to the generated core facts list, which supplies the page title and the #legacy-facts anchor. -->
This page lists the built-in facts that ship with OpenFact. Not every fact applies to every system,
and your site might also use [custom facts](custom_facts.html) and
[external facts](external_facts.html) that your modules distribute.

To see every fact on a node, including the ones your modules add, run `puppet facts show`. If you
use [Puppetboard](https://github.com/voxpupuli/puppetboard) with OpenVoxDB, you can also browse
facts in its web interface.

In manifests, read facts from the `$facts` hash, for example `$facts['os']['family']`. For more
information, see [Facts and built-in variables](/openvox/latest/lang_facts_and_builtin_vars.html).

> **Legacy facts:** The facts in the [Legacy Facts](#legacy-facts) section, such as `osfamily` and
> `architecture`, come from older versions of Facter. Their data is also in structured facts, for
> example `os.family` and `os.architecture`. Since OpenVox 8, agents do not send legacy facts to
> the server, because the `include_legacy_facts` setting defaults to `false`. A manifest that uses
> `$osfamily` fails with "Unknown variable", and `$facts['osfamily']` is empty, so use the
> structured facts instead. If you still depend on legacy facts, set `include_legacy_facts = true`
> in `puppet.conf` on your agents while you migrate. `facter` and `puppet facts show` also hide
> legacy facts unless you pass `--show-legacy` or ask for a fact by name.

* * *
