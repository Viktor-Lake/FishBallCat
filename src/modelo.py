import numpy as np
import glm
import pygame as pg

class Cube:
     def __init__(self, game):
          self.game           = game
          self.ctx            = game.ctx
          self.vbo            = self.get_vbo()
          self.shader_program = self.get_shader_program('default')
          self.vao            = self.get_vao()
          self.model_m        = self.get_model_matrix()
          self.texture        = self.get_texture(path='../assets/textures/caixa.jpeg')
          self.on_init()

     def get_texture(self, path):
          texture = pg.image.load(path).convert()
          texture = pg.transform.flip(texture,flip_x=False, flip_y=True)
          # texture.fill('blue')
          texture = self.ctx.texture(size=texture.get_size(),components=3, data=pg.image.tostring(texture,'RGB'))
          return texture

     def get_model_matrix(self):
          model_m = glm.mat4()
          return model_m

     def on_init(self):
          # Iluminação
          self.shader_program['phong_light.position'].write(self.game.phong_light.position)
          self.shader_program['phong_light.Ia'].write(self.game.phong_light.Ia)
          self.shader_program['phong_light.Id'].write(self.game.phong_light.Id)
          self.shader_program['phong_light.Is'].write(self.game.phong_light.Is)

          # Textura
          self.shader_program['u_texture_0'] = 0
          self.texture.use()

          # Matrizes de posição
          self.shader_program['proj_m'].write(self.game.camera.proj_m)
          self.shader_program['view_m'].write(self.game.camera.view_m)
          self.shader_program['model_m'].write(self.model_m)

     def update(self):
          model_m = glm.rotate(self.model_m, self.game.time * 0.5, glm.vec3(0, 1, 0))
          self.shader_program['model_m'].write(model_m)
          self.shader_program['view_m'].write(self.game.camera.view_m)
          self.shader_program['camPos'].write(self.game.camera.position)

     def render(self):
          self.update()
          self.vao.render()

     def destroy(self):
          self.vbo.release()
          self.shader_program.release()
          self.vao.release()

     def get_vao(self):
          vao = self.ctx.vertex_array(self.shader_program, [(self.vbo, '2f 3f 3f', 'in_texcoord_0', 'in_normal', 'in_position')])
          return vao

     def get_vertex_data(self):
          vertices = [ (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1),
                          (-1, 1, -1), (-1, -1, -1), (1, -1, -1), (1, 1, -1)]

          indices  = [ (0, 2, 3), (0, 1, 2), (1, 7, 2), (1, 6, 7),
                          (6, 5, 4), (4, 7, 6), (3, 4, 5), (3, 5, 0),
                          (3, 7, 4), (3, 2, 7), (0, 6, 1), (0, 5, 6) ]

          vertex_data = self.get_data(vertices, indices)

          tex_coord = [(0, 0),(1,0),(1,1),(0,1)]
          tex_coord_indices = [(0,2,3),(0,1,2),
                              (0,2,3),(0,1,2),
                              (0,1,2),(2,3,0),
                              (2,3,0),(2,0,1),
                              (0,2,3),(0,1,2),
                              (3,1,2),(3,0,1)]
          tex_coord_data = self.get_data(tex_coord,tex_coord_indices)

          nfaces      = 6
          normals     = [ (0, 0, 1) * nfaces, (1, 0, 0) * nfaces, (0, 0, -1) * nfaces,
                         (-1, 0, 0) * nfaces, (0, 1, 0) * nfaces, (0, -1, 0) * nfaces ]
          normals     = np.array(normals, dtype = 'f4').reshape(36, 3)

          vertex_data = np.hstack([normals, vertex_data])
          vertex_data = np.hstack([tex_coord_data,vertex_data])

          return vertex_data

     @staticmethod
     def get_data(vertices, indices):
          data        = [ vertices[i] for model in indices for i in model ]
          return np.array(data, dtype = np.float32)

     def get_vbo(self):
          vertex_data = self.get_vertex_data()
          vbo         = self.ctx.buffer(vertex_data)
          return vbo

     def get_shader_program(self, shader_name):
          with open(f'shaders/{shader_name}.vert') as file:
               vertex_shader   = file.read()

          with open(f'shaders/{shader_name}.frag') as file:
               fragment_shader = file.read()

          program = self.ctx.program(vertex_shader = vertex_shader, fragment_shader = fragment_shader)
          return program