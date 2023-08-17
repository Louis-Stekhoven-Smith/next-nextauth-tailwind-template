import { PrismaClient } from "@prisma/client"

export const prisma = new PrismaClient()

async function runSeeds() {
  // Seed your data
  const someTableData = [{
    "id": 1,
    "columnName": "columnData"
  }]

  await prisma.someTable.createMany({
    data: someTableData,
  })
}

void runSeeds()
