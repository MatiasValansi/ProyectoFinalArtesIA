import express from "express"
import { config } from "./config/config.js"
import { statusRouter } from "./routes/statusRouter.js"
import { userRouter } from "./routes/userRouter.js"
import { caseRouter } from "./routes/caseRouter.js"

const app = express()

app.use(express.json())

app.use(statusRouter)
app.use("/api",userRouter)
app.use("/api",caseRouter)

app.get("/",
    (req,res)=> {
        res.json({
            url: config.SUPABASE_URL
        })
    }
)

app.listen(
    config.PORT,
    () => {
        const message = `Server running in http://${config.HOST}:${config.PORT} ✅✅✅`
        console.log(message);        
    }
)