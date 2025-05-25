# Python Module Path Fix

## Issue

When running the OpenHands service through the NixOS module, the following error occurred:

```
systemd[1]: Started OpenHands AI software engineer.
openhands-server[365708]: /nix/store/mljjgfz1maz00j8fjz7ynsdyvajggmzf-python3-3.12.10-env/bin/python3.12: Error while finding module specification for 'openhands.server.main' (ModuleNotFoundError: No module named 'openhands.server')
systemd[1]: openhands.service: Main process exited, code=exited, status=1/FAILURE
```

## Root Cause

The issue was in the `package.nix` file, where we were setting the `PYTHONPATH` environment variable incorrectly. We were using:

```nix
--set PYTHONPATH "$out/lib:$PYTHONPATH"
```

But the Python modules were installed to `$out/lib/openhands/`. This meant Python was looking for the `openhands` module in `$out/lib/`, but it needed to look in `$out/` directly.

## Solution

We changed the `PYTHONPATH` setting to:

```nix
--set PYTHONPATH "$out:$PYTHONPATH"
```

This ensures that Python can find the `openhands` module correctly.

## Testing

After making this change, the package builds successfully with:

```bash
nix build .#openhands --no-link
```

And the service should now start correctly without the module not found error.

## Additional Notes

When setting up Python packages in Nix, it's important to ensure that the module paths are correctly set. The `PYTHONPATH` environment variable should point to the directory that contains the top-level module, not the module itself.

In our case, the directory structure is:
```
$out/
  lib/
    openhands/
      __init__.py
      server/
        main.py
      cli/
        main.py
```

So we need to set `PYTHONPATH` to `$out` to ensure Python can find the `openhands` module.