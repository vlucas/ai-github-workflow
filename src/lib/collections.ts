import { createCollection } from '@tanstack/react-db'
import { queryCollectionOptions } from '@tanstack/query-db-collection'
import { QueryClient } from '@tanstack/query-core'
import { selectConfigSchema, selectTodoSchema } from '../db/validation'
import { api } from './api'

const queryClient = new QueryClient()

export const todoCollection = createCollection(
  queryCollectionOptions({
    id: `todos`,
    queryKey: [`todos`],
    refetchInterval: 3000,
    queryFn: async () => {
      const rows = await api.todos.getAll()
      return rows.map((todo) => ({
        ...todo,
        created_at: new Date(todo.created_at),
        updated_at: new Date(todo.updated_at),
      }))
    },
    getKey: (item) => item.id,
    schema: selectTodoSchema,
    queryClient,
    onInsert: async ({ transaction }) => {
      const {
        id: _id,
        created_at: _createdAt,
        updated_at: _updatedAt,
        ...modified
      } = transaction.mutations[0].modified
      return await api.todos.create(modified)
    },
    onUpdate: async ({ transaction }) => {
      return await Promise.all(
        transaction.mutations.map(async (mutation) => {
          const { original, changes } = mutation
          if (!(`id` in original)) {
            throw new Error(`Original todo not found for update`)
          }
          return await api.todos.update(original.id, changes)
        }),
      )
    },
    onDelete: async ({ transaction }) => {
      return await Promise.all(
        transaction.mutations.map(async (mutation) => {
          const { original } = mutation
          if (!(`id` in original)) {
            throw new Error(`Original todo not found for delete`)
          }
          await api.todos.delete(original.id)
        }),
      )
    },
  }),
)

export const configCollection = createCollection(
  queryCollectionOptions({
    id: `config`,
    queryKey: [`config`],
    refetchInterval: 3000,
    queryFn: async () => {
      const rows = await api.config.getAll()
      return rows.map((row) => ({
        ...row,
        created_at: new Date(row.created_at),
        updated_at: new Date(row.updated_at),
      }))
    },
    getKey: (item) => item.id,
    schema: selectConfigSchema,
    queryClient,
    onInsert: async ({ transaction }) => {
      const modified = transaction.mutations[0].modified
      return await api.config.create(modified)
    },
    onUpdate: async ({ transaction }) => {
      return await Promise.all(
        transaction.mutations.map(async (mutation) => {
          const { original, changes } = mutation
          if (!(`id` in original)) {
            throw new Error(`Original config not found for update`)
          }
          return await api.config.update(original.id, changes)
        }),
      )
    },
  }),
)
