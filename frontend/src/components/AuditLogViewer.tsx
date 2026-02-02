import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Chip,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import RefreshIcon from '@mui/icons-material/Refresh';
import { AuditLog } from '../types';
import { apiService } from '../services/api';

const AuditLogViewer: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const data = await apiService.getLogs(100);
      setLogs(data);
    } catch (error) {
      console.error('Failed to fetch logs:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const columns: GridColDef[] = [
    {
      field: 'timestamp',
      headerName: '日時',
      width: 180,
      valueFormatter: (params) => {
        return new Date(params.value).toLocaleString('ja-JP');
      },
    },
    {
      field: 'action',
      headerName: '操作',
      width: 150,
    },
    {
      field: 'target_user',
      headerName: '対象ユーザー',
      width: 150,
      valueFormatter: (params) => params.value || '-',
    },
    {
      field: 'aws_account',
      headerName: 'アカウント',
      width: 150,
    },
    {
      field: 'operator_ip',
      headerName: '操作者IP',
      width: 150,
    },
    {
      field: 'status',
      headerName: 'ステータス',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={params.value === 'success' ? 'success' : 'error'}
          size="small"
        />
      ),
    },
    {
      field: 'error_message',
      headerName: 'エラーメッセージ',
      flex: 1,
      minWidth: 200,
      valueFormatter: (params) => params.value || '-',
    },
  ];

  return (
    <Paper sx={{ p: 3 }}>
      <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h6">操作ログ</Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={fetchLogs}
          disabled={loading}
        >
          更新
        </Button>
      </Box>

      <DataGrid
        rows={logs}
        columns={columns}
        getRowId={(row) => row.operation_id}
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
    </Paper>
  );
};

export default AuditLogViewer;
