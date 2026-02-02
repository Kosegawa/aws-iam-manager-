import React, { useState, useEffect } from 'react';
import {
  Container,
  Paper,
  Typography,
  Box,
  Alert,
  Tabs,
  Tab,
  CssBaseline,
} from '@mui/material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import AccountSelector from './components/AccountSelector';
import UserList from './components/UserList';
import CreateUserModal from './components/CreateUserModal';
import AuditLogViewer from './components/AuditLogViewer';
import { AWSAccount, IAMUser } from './types';
import { apiService } from './services/api';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`tabpanel-${index}`}
      aria-labelledby={`tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

function App() {
  const [accounts, setAccounts] = useState<AWSAccount[]>([]);
  const [selectedAccount, setSelectedAccount] = useState<string>('');
  const [users, setUsers] = useState<IAMUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [tabValue, setTabValue] = useState(0);

  useEffect(() => {
    fetchAccounts();
  }, []);

  useEffect(() => {
    if (selectedAccount) {
      fetchUsers();
    }
  }, [selectedAccount]);

  const fetchAccounts = async () => {
    try {
      const data = await apiService.getAccounts();
      setAccounts(data);
      if (data.length > 0 && !selectedAccount) {
        setSelectedAccount(data[0].name);
      }
    } catch (err: any) {
      setError('アカウント一覧の取得に失敗しました');
      console.error(err);
    }
  };

  const fetchUsers = async () => {
    if (!selectedAccount) return;

    setLoading(true);
    setError(null);

    try {
      const data = await apiService.getUsers(selectedAccount);
      setUsers(data);
    } catch (err: any) {
      setError('ユーザー一覧の取得に失敗しました');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (username: string, sendNotification: boolean) => {
    await apiService.createUser(selectedAccount, { username, send_notification: sendNotification });
    await fetchUsers();
  };

  const handleDeleteUser = async (username: string) => {
    try {
      await apiService.deleteUser(selectedAccount, username);
      await fetchUsers();
    } catch (err: any) {
      setError(`ユーザー ${username} の削除に失敗しました`);
      console.error(err);
    }
  };

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Container maxWidth="xl" sx={{ py: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          AWS IAM Manager
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        <Paper sx={{ p: 3, mb: 3 }}>
          <Tabs value={tabValue} onChange={handleTabChange}>
            <Tab label="IAMユーザー管理" />
            <Tab label="操作ログ" />
          </Tabs>

          <TabPanel value={tabValue} index={0}>
            <AccountSelector
              accounts={accounts}
              selectedAccount={selectedAccount}
              onAccountChange={setSelectedAccount}
            />

            <UserList
              users={users}
              loading={loading}
              onRefresh={fetchUsers}
              onDeleteUser={handleDeleteUser}
              onCreateUser={() => setCreateModalOpen(true)}
            />
          </TabPanel>

          <TabPanel value={tabValue} index={1}>
            <AuditLogViewer />
          </TabPanel>
        </Paper>

        <CreateUserModal
          open={createModalOpen}
          onClose={() => setCreateModalOpen(false)}
          onCreateUser={handleCreateUser}
        />
      </Container>
    </ThemeProvider>
  );
}

export default App;
