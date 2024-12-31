# Stacks ,Token Vesting Contract with Internal Token Implementation

This smart contract implements a configurable token vesting system, including built-in functionality for managing a fungible token. It is designed for use cases where tokens need to be distributed to recipients over a defined schedule, ensuring compliance with predefined conditions.

## Features

- **Fungible Token Support**: Implements a fungible token (compliant with SIP-010) with custom name, symbol, decimals, and URI.
- **Vesting Schedules**: Allows the creation of vesting schedules with configurable start times, cliff periods, durations, and optional milestones.
- **Safe Arithmetic Operations**: Includes safeguards to prevent arithmetic overflows during calculations.
- **Releasable Tokens**: Tracks vested and released token amounts for each recipient, enabling partial or full release over time.
- **Milestone Support**: Supports up to 10 milestones for flexible vesting configurations.

---

## Deployment and Initialization

### Contract Deployment
Ensure the contract is deployed by the intended owner. The deploying account becomes the `contract-owner`.

### Initialization
After deployment, initialize the contract by calling the `initialize` function.

#### Parameters:
- `name`: The name of the fungible token (e.g., "VestingToken").
- `symbol`: The token symbol (e.g., "VST").
- `decimals`: Number of decimal places for the token.
- `uri`: A string pointing to metadata or documentation about the token.
- `initial-supply`: The initial supply of tokens to be minted and assigned to the contract owner.

#### Example:
```clojure
(initialize "VestingToken" "VST" u6 "https://example.com/token" u1000000)
```

---

## Vesting Schedule Management

### Create Vesting Schedule
The contract owner can create a vesting schedule for a recipient using `create-vesting-schedule`.

#### Parameters:
- `recipient`: The recipient's principal address.
- `total-amount`: Total amount of tokens to be vested.
- `start-block`: Block number when vesting begins.
- `cliff-blocks`: Duration in blocks before tokens start vesting.
- `duration-blocks`: Total duration of the vesting period in blocks.
- `milestones`: Optional list of up to 10 milestones, each defining a block number and percentage of tokens vested at that milestone.
- `milestone-count`: The number of milestones in the list.

#### Example:
```clojure
(create-vesting-schedule
  tx-sender
  u1000
  u100
  u50
  u500
  [(tuple (block u150) (percentage u25)) (tuple (block u200) (percentage u50))]
  u2)
```

### Retrieve Vesting Schedule
Use `get-vesting-schedule` to fetch details of a vesting schedule for a given recipient.

#### Parameters:
- `recipient`: The recipient’s principal address.

#### Example:
```clojure
(get-vesting-schedule tx-sender)
```

---

## Token Vesting

### Release Tokens
Recipients can release their vested tokens by calling `release`. This calculates the amount vested so far and transfers the unreleased portion to the recipient.

#### Example:
```clojure
(release)
```

### View Vested and Releasable Amounts
- `get-vested-amount`: Returns the total amount of tokens vested for a recipient.
- `get-releasable-amount`: Returns the amount of tokens that can be released to the recipient.

#### Example:
```clojure
(get-vested-amount tx-sender)
(get-releasable-amount tx-sender)
```

---

## SIP-010 Token Standard Compliance

The contract complies with the SIP-010 token standard, providing the following functions:

- `get-name`: Returns the token's name.
- `get-symbol`: Returns the token's symbol.
- `get-decimals`: Returns the number of decimals used by the token.
- `get-balance`: Returns the token balance of a specified account.
- `get-total-supply`: Returns the total token supply.
- `get-token-uri`: Returns the token’s metadata URI.

#### Example:
```clojure
(get-name)
(get-balance tx-sender)
```

---

## Error Codes

The contract includes comprehensive error handling to ensure robustness. Key error codes include:

- `u100`: Only the contract owner can perform this action.
- `u101`: Contract has already been initialized.
- `u102`: Contract is not initialized.
- `u103`: Vesting schedule not found.
- `u104`: Invalid recipient address.
- `u105`: Insufficient balance for the operation.
- `u106`: Cliff period has not been reached.
- `u107`: Invalid milestone configuration.
- `u108`: Token transfer failed.
- `u109`: Arithmetic overflow detected.
- `u110`: Invalid input provided.

---

## Security Considerations

1. **Owner Privileges**: Only the contract owner can initialize the contract and create vesting schedules. Ensure the owner’s account is secure.
2. **Token Transfers**: All token transfers are handled internally using the SIP-010 standard functions to prevent unauthorized actions.
3. **Arithmetic Safety**: All arithmetic operations are wrapped with checks to prevent overflows.
4. **Vesting Schedule Validations**: Milestone percentages and durations are validated to prevent logical errors.

---

## Limitations

- **Milestone Count**: Supports up to 10 milestones per schedule.
- **Immutable Vesting Schedule**: Once created, vesting schedules cannot be modified. Plan schedules carefully before creation.

---

## Testing and Usage

Ensure thorough testing of all contract functions in a testnet environment before deploying on the mainnet. Use Clarity-relevant testing frameworks to simulate vesting scenarios.

---