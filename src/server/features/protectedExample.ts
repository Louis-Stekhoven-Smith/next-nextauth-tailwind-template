import { protectedProcedure } from "~/server/middleware/trpc"
import { type PrismaClient } from "@prisma/client"
// The controller
export const protectedExample = {
  protectedExample: protectedProcedure.query(({ ctx }) => {
    try {
      return service(ctx.session.user.id, ctx.prisma)
    } catch (err) {
      console.log(err)
      throw err
    }
  }),
}

function service(userId: string, prisma: PrismaClient) {

  // prisma.example.findMany()
  return `Hello ${userId} you can now see this secret message!`
}
