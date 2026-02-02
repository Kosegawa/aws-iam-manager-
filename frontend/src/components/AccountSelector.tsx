import React from 'react';
import { FormControl, InputLabel, Select, MenuItem, SelectChangeEvent } from '@mui/material';
import { AWSAccount } from '../types';

interface AccountSelectorProps {
  accounts: AWSAccount[];
  selectedAccount: string;
  onAccountChange: (accountName: string) => void;
}

const AccountSelector: React.FC<AccountSelectorProps> = ({
  accounts,
  selectedAccount,
  onAccountChange,
}) => {
  const handleChange = (event: SelectChangeEvent) => {
    onAccountChange(event.target.value);
  };

  return (
    <FormControl fullWidth sx={{ mb: 3 }}>
      <InputLabel id="account-select-label">AWSアカウント</InputLabel>
      <Select
        labelId="account-select-label"
        id="account-select"
        value={selectedAccount}
        label="AWSアカウント"
        onChange={handleChange}
      >
        {accounts.map((account) => (
          <MenuItem key={account.name} value={account.name}>
            {account.name} ({account.account_id})
          </MenuItem>
        ))}
      </Select>
    </FormControl>
  );
};

export default AccountSelector;
