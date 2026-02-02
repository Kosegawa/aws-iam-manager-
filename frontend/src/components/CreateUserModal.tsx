import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  FormControlLabel,
  Checkbox,
  Alert,
} from '@mui/material';

interface CreateUserModalProps {
  open: boolean;
  onClose: () => void;
  onCreateUser: (username: string, sendNotification: boolean) => Promise<void>;
}

const CreateUserModal: React.FC<CreateUserModalProps> = ({ open, onClose, onCreateUser }) => {
  const [username, setUsername] = useState('');
  const [sendNotification, setSendNotification] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async () => {
    if (!username.trim()) {
      setError('ユーザー名を入力してください');
      return;
    }

    // IAMユーザー名の検証
    const iamUsernameRegex = /^[\w+=,.@-]+$/;
    if (!iamUsernameRegex.test(username)) {
      setError('ユーザー名に使用できる文字は英数字と += , . @ - のみです');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await onCreateUser(username, sendNotification);
      setUsername('');
      setSendNotification(true);
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.detail || 'ユーザーの作成に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setUsername('');
      setError(null);
      setSendNotification(true);
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>新規IAMユーザー作成</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}
        <TextField
          autoFocus
          margin="dense"
          label="ユーザー名"
          type="text"
          fullWidth
          variant="outlined"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          disabled={loading}
          sx={{ mt: 1 }}
        />
        <FormControlLabel
          control={
            <Checkbox
              checked={sendNotification}
              onChange={(e) => setSendNotification(e.target.checked)}
              disabled={loading}
            />
          }
          label="作成通知をメールで送信"
          sx={{ mt: 2 }}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          キャンセル
        </Button>
        <Button onClick={handleSubmit} variant="contained" disabled={loading}>
          {loading ? '作成中...' : '作成'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CreateUserModal;
