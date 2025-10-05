import express from "express"
import { config } from "./config/config.js"
import { statusRouter } from "./routes/statusRouter.js"
import { userRouter } from "./routes/userRouter.js"
import { caseRouter } from "./routes/caseRouter.js"
import { SupabaseUserRepository } from "./repository/user.supabase.repository.js"

const app = express()

app.use(express.json())

app.use(statusRouter)
app.use("/api",userRouter)
app.use("/api",caseRouter)


app.post("/crear-user", async (req,res) => {
    const user = req.body
    const {data,error} = await SupabaseUserRepository.userCreateOne(user)
    return res.json({data,error})
})

app.delete("/:id", async (req, res) => {
    const { id } = req.params;
    const {data, error} = await SupabaseUserRepository.userDeleteOneById(id)
    return res.json({data, error})
})

app.listen(
    config.PORT,
    () => {
        const message = `Server running in http://${config.HOST}:${config.PORT} ✅✅✅`
        console.log(message);        
    }
)