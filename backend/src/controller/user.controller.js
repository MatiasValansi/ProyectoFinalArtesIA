import { UserService } from "../service/user.service.js";

export const UserController = {

    userAll: async (req, res) =>{
        const allUsers = await UserService.serviceUserAll()

        if(!allUsers){
            res.status(404).json({
                payload: null,
                message: "No hay usuarios",
                ok:false,
            })
            return null
        } else {
            res.status(200).json({
                message:"Success 🟢🟢🟢",
                payload: allUsers,
                ok:true
            })
        }
    },

    userValidation : async (req,res) => {
        const {id} = req.params;
        const userById = await UserService.serviceUserValidation(id)

        if(!userById){
            res.status(404).json({
                payload: null,
                message: "El usuario no fue hallado",
                ok:false,
            })
            return null
        } else {
            res.status(200).json({
                message:"Success 🟢🟢🟢",
                payload: userById.id,
                ok:true
            })
        }
    },

    userCreateOne : async (req,res) => {
        const {user} = req.body

        try{
            const userCreated = await UserService.serviceUserCreation(user)            
            res.status(200).json({
                message: "🟢 Success 🟢 --> Usuario creado con exito",
                payload: {userCreated},
                ok: true
            })
            return            
        }
        catch(e){
            res.status(404).json({
                payload: null,
                message: "No se pudo crear el usuario",
                error: e.message,
                ok: false
            })
            return            
        }
    },

    userDeleteOne : async (req, res) => {
        const {id} = req.params
        const idUser = await UserService.serviceUserDelete(id)

        if (!idUser) {
            res.status(404).json({
                payload: null,
                message: "No se pudo borrar el usuario",
                ok: false
            })
            return
        }

        res.status(200).json({
            message: `Success: ${idUser}`,
            payload: { idUser },
            ok: true
        })
        return
    },

    userUpdateOne : async (req,res) => {
        
    }

}