import express from "express"
import { config } from "./config/config.js"
import { statusRouter } from "./routes/statusRouter.js"
import { userRouter } from "./routes/userRouter.js"

const app = express()

app.use(express.json())

app.use(statusRouter)
app.use("/api",userRouter)

app.listen(
    config.PORT,
    () => {
        const message = `Server running in http://${config.HOST}:${config.PORT} ✅✅✅`
        console.log(message);        
    }
)