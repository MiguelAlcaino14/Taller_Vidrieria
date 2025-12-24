import { api } from './api';

export const supabase = {
  from: (table: string) => ({
    select: (columns = '*') => ({
      eq: (column: string, value: any) => ({
        maybeSingle: async () => {
          try {
            const data = await api.get(`/api/${table}?${column}=${value}`);
            return { data, error: null };
          } catch (error) {
            return { data: null, error };
          }
        },
        single: async () => {
          try {
            const data = await api.get(`/api/${table}?${column}=${value}`);
            return { data, error: null };
          } catch (error) {
            return { data: null, error };
          }
        }
      }),
      order: (column: string, options?: { ascending: boolean }) => ({
        then: async (resolve: (value: any) => void) => {
          try {
            const data = await api.get(`/api/${table}`);
            resolve({ data, error: null });
          } catch (error) {
            resolve({ data: null, error });
          }
        }
      })
    }),
    insert: (data: any) => ({
      select: () => ({
        single: async () => {
          try {
            const result = await api.post(`/api/${table}`, data);
            return { data: result, error: null };
          } catch (error) {
            return { data: null, error };
          }
        }
      })
    }),
    update: (data: any) => ({
      eq: async (column: string, value: any) => {
        try {
          await api.put(`/api/${table}/${value}`, data);
          return { error: null };
        } catch (error) {
          return { error };
        }
      }
    }),
    delete: () => ({
      eq: async (column: string, value: any) => {
        try {
          await api.delete(`/api/${table}/${value}`);
          return { error: null };
        } catch (error) {
          return { error };
        }
      }
    })
  }),
  storage: {
    from: (bucket: string) => ({
      upload: async (path: string, file: File) => {
        return { data: null, error: new Error('Storage no implementado aún') };
      },
      getPublicUrl: (path: string) => ({
        data: { publicUrl: '' }
      })
    })
  }
};
