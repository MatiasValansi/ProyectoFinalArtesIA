import { USER_ROLES } from "../config/roles.js"
import {supabase} from "../db/supabase.js"

export const SupabaseUserRepository = {
    getAll: async () => {
        let { data: users} = await supabase
        .from('users')
        .select('*')
        return users
},

    userCreateOne: async (user) => {
       const { data, error } = await supabase
      .from('users')
      .insert([
            {
              name: user.name,
              email: user.email,
              password: user.password, // cambia por hashedPassword si usás bcrypt
              role: user.role ?? USER_ROLES.USER,
            },
          ])
      .select()
         

      if (error) {
          throw error
        }
        return data
      },

    userDeleteOneById: async (idUserToDelete) => {       
        //Primero busco el ID a eliminar para verificar que existe, como buena práctica aprendida en la facultad, y luego lo elimino
                
        let { data: userToDelete, error } = await supabase
        .from('users')
        .select('*')
        .eq('id',idUserToDelete)
         

        if (error) {
        console.error("Error al buscar el Usuario:", error.message);
        return { error };
        }
                
        const {data: usuarioEliminado, error: errorDel } = await supabase
        .from('users')
        .delete()
        .eq('id', idUserToDelete)

        return {data: userToDelete}
    }  

}
    

