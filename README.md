**[Symbiotic Protocol](https://symbiotic.fi) is an extremely flexible and permissionless shared security system.**

This repository contains Symbiotic Periphery contracts:

- Default Collateral Migrator - to withdraw an underlying asset and deposit it to a vault in one transaction

## Security

Security audits can be found [here](./audits).

## Usage

### Env

Create `.env` file using a template:

```
ETH_RPC_URL=
ETHERSCAN_API_KEY=
```

\* ETHERSCAN_API_KEY is optional.

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```
