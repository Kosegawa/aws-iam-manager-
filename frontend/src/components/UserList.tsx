import React, { useState } from 'react';
import {
  Box,
  Button,
  TextField,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import { DataGrid, GridColDef, GridRenderCellParams } from '@mui/x-data-grid';
import DeleteIcon from '@mui/icons-material/Delete';
import RefreshIcon from '@mui/icons-material/Refresh';
import AddIcon from '@mui/icons-material/Add';
import { IAMUser } from '../types';

interface UserListProps {
  users: IAMUser[];
  loading: boolean;
  onRefresh: () => void;
  onDeleteUser: (username: string) => void;
  onCreateUser: () => void;
}

const UserList: React.FC<UserListProps> = ({
  users,
  loading,
  onRefresh,
  onDeleteUser,
  onCreateUser,
}) => {
  const [searchText, setSearchText] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState<string | null>(null);

  const handleDeleteClick = (username: string) => {
    setUserToDelete(username);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (userToDelete) {
      onDeleteUser(userToDelete);
    }
    setDeleteDialogOpen(false);
    setUserToDelete(null);
  };

  const handleDeleteCancel = () => {
    setDeleteDialogOpen(false);
    setUserToDelete(null);
  };

  const filteredUsers = users.filter((user) =>
    user.username.toLowerCase().includes(searchText.toLowerCase())
  );

  const columns: GridColDef[] = [
    {
      field: 'username',
      headerName: 'ユーザー名',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'user_id',
      headerName: 'ユーザーID',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'create_date',
      headerName: '作成日',
      flex: 1,
      minWidth: 200,
      valueFormatter: (params) => {
        return new Date(params.value).toLocaleString('ja-JP');
      },
    },
    {
      field: 'password_last_used',
      headerName: '最終パスワード使用日',
      flex: 1,
      minWidth: 200,
      valueFormatter: (params) => {
        return params.value ? new Date(params.value).toLocaleString('ja-JP') : '未使用';
      },
    },
    {
      field: 'actions',
      headerName: '操作',
      width: 100,
      sortable: false,
      renderCell: (params: GridRenderCellParams) => (
        <IconButton
          color="error"
          onClick={() => handleDeleteClick(params.row.username)}
          size="small"
        >
          <DeleteIcon />
        </IconButton>
      ),
    },
  ];

  return (
    <Box>
      <Box sx={{ mb: 2, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          label="ユーザー名で検索"
          variant="outlined"
          size="small"
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          sx={{ flexGrow: 1 }}
        />
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={onCreateUser}
        >
          ユーザー作成
        </Button>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={onRefresh}
          disabled={loading}
        >
          更新
        </Button>
      </Box>

      <DataGrid
        rows={filteredUsers}
        columns={columns}
        getRowId={(row) => row.username}
        loading={loading}
        pageSizeOptions={[10, 25, 50, 100]}
        initialState={{
          pagination: {
            paginationModel: { pageSize: 25 },
          },
        }}
        autoHeight
        disableRowSelectionOnClick
      />

      <Dialog open={deleteDialogOpen} onClose={handleDeleteCancel}>
        <DialogTitle>ユーザーの削除</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ユーザー「{userToDelete}」を削除してもよろしいですか？
            <br />
            この操作は取り消せません。
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeleteCancel}>キャンセル</Button>
          <Button onClick={handleDeleteConfirm} color="error" variant="contained">
            削除
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UserList;
