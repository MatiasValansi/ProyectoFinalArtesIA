import { JsonHandler } from "../utils/JsonManager.js"

export const UserRepository = {
    getAll: async () => await JsonHandler.read(),

    getById: async (id) => {
        const users = await JsonHandler.read()

        if (!users) return null

        const userFound = users.find((userById) => userById.id == id)

        if (!userFound) return null

        return userFound
    },


    createOne: async (userToCreate) => {
        const users = await JsonHandler.read()
        users.push(userToCreate);
        try {
            await JsonHandler.write(users)
        } catch (e) {
            console.error({message: e.message});            
        }
    }
}