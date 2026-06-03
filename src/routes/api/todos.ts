import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { db } from '../../db'
import { todos } from '../../db/schema'
import { validateInsertTodo } from '../../db/validation'

export const Route = createFileRoute(`/api/todos`)({
  server: {
    handlers: {
      GET: async () => {
        try {
          const rows = await db.select().from(todos)
          return json(rows)
        } catch (error) {
          console.error(`Error fetching todos:`, error)
          return json(
            {
              error: `Failed to fetch todos`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
      POST: async ({ request }) => {
        try {
          const body = await request.json()
          const todoData = validateInsertTodo(body)
          const [newTodo] = await db.insert(todos).values(todoData).returning()

          return json({ todo: newTodo }, { status: 201 })
        } catch (error) {
          console.error(`Error creating todo:`, error)
          return json(
            {
              error: `Failed to create todo`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
    },
  },
})
