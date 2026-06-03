import * as React from 'react'
import { createFileRoute } from '@tanstack/react-router'
import { useLiveQuery } from '@tanstack/react-db'
import { configCollection, todoCollection } from '../lib/collections'
import { TodoApp } from '../components/TodoApp'
import { api } from '../lib/api'
import type { Transaction } from '@tanstack/react-db'

export const Route = createFileRoute(`/`)({
  component: HomePage,
  ssr: false,
  loader: async () => {
    await Promise.all([
      todoCollection.preload(),
      configCollection.preload(),
    ])

    return null
  },
})

function HomePage() {
  const { data: todos } = useLiveQuery((q) =>
    q
      .from({ todo: todoCollection })
      .orderBy(({ todo }) => todo.created_at, `asc`),
  )

  const { data: configData } = useLiveQuery((q) =>
    q.from({ config: configCollection }),
  )

  const configMutationFn = async ({
    transaction,
  }: {
    transaction: Transaction
  }) => {
    const inserts = transaction.mutations.filter((m) => m.type === `insert`)
    await Promise.all(
      inserts.map(async (mutation) => {
        await api.config.create(mutation.modified)
      }),
    )

    const updates = transaction.mutations.filter((m) => m.type === `update`)
    await Promise.all(
      updates.map(async (mutation) => {
        if (!(`id` in mutation.original)) {
          throw new Error(`Original config not found for update`)
        }
        await api.config.update(mutation.original.id, mutation.changes)
      }),
    )

    await configCollection.utils.refetch()
  }

  return (
    <TodoApp
      todos={todos}
      configData={configData}
      todoCollection={todoCollection}
      configCollection={configCollection}
      title="todos"
      configMutationFn={configMutationFn}
    />
  )
}
