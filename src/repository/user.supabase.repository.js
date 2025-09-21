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
          admin: user.admin ?? false,
        },
      ])
  .select()

   if (error) {
      throw error
    }
    return data
  },

}
    

