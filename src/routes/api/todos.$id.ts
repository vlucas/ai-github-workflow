import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { eq } from 'drizzle-orm'
import { db } from '../../db'
import { todos } from '../../db/schema'
import { validateUpdateTodo } from '../../db/validation'

export const Route = createFileRoute(`/api/todos/$id`)({
  server: {
    handlers: {
      GET: async ({ params }) => {
        try {
          const id = Number(params.id)
          const [todo] = await db
            .select()
            .from(todos)
            .where(eq(todos.id, id))

          if (!todo) {
            return json({ error: `Todo not found` }, { status: 404 })
          }

          return json(todo)
        } catch (error) {
          console.error(`Error fetching todo:`, error)
          return json(
            {
              error: `Failed to fetch todo`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
      PUT: async ({ params, request }) => {
        try {
          const id = Number(params.id)
          const body = await request.json()
          const todoData = validateUpdateTodo(body)

          const [updatedTodo] = await db
            .update(todos)
            .set({ ...todoData, updated_at: new Date() })
            .where(eq(todos.id, id))
            .returning()

          if (!updatedTodo) {
            return json({ error: `Todo not found` }, { status: 404 })
          }

          return json({ todo: updatedTodo })
        } catch (error) {
          console.error(`Error updating todo:`, error)
          return json(
            {
              error: `Failed to update todo`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
      DELETE: async ({ params }) => {
        try {
          const id = Number(params.id)
          const [deleted] = await db
            .delete(todos)
            .where(eq(todos.id, id))
            .returning({ id: todos.id })

          if (!deleted) {
            return json({ error: `Todo not found` }, { status: 404 })
          }

          return json({ success: true })
        } catch (error) {
          console.error(`Error deleting todo:`, error)
          return json(
            {
              error: `Failed to delete todo`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
    },
  },
})
