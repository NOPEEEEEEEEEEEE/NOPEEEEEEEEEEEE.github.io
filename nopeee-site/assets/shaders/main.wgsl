struct Uniforms {

  resolution: vec2f,
  time: f32,
}



@group(0) @binding(0) var<uniform> uniforms: Uniforms;

// Constants for materials
const MAT_GROUND = 0.0;
const MAT_STEM = 1.0;
const MAT_ROSE = 2.0;

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4f {
  var pos = array<vec2f, 3>(
    vec2f(-1.0, -1.0),
    vec2f(3.0, -1.0),
    vec2f(-1.0, 3.0)
  );
  return vec4f(pos[in_vertex_index], 0.0, 1.0);
}



// --- SDF Primitive Helpers ---

fn rot2D(p: vec2f, angle: f32) -> vec2f {
    let s = sin(angle);
    let c = cos(angle);
    return vec2f(c * p.x - s * p.y, s * p.x + c * p.y);
}

fn sdSphere(p: vec3f, s: f32) -> f32 {
  return length(p) - s;
}

fn sdCappedCylinder(p: vec3f, h: f32, r: f32) -> f32 {
  let d = abs(vec2f(length(p.xz),p.y)) - vec2f(r,h);
  // FIXED: max(d, vec2f(0.0)) instead of max(d, 0.0)
  return min(max(d.x,d.y),0.0) + length(max(d, vec2f(0.0)));
}

fn sdEllipsoid(p: vec3f, r: vec3f) -> f32 {
    let k0 = length(p/r);
    let k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// --- SDF Combination Helpers ---

fn smin(a: f32, b: f32, k: f32) -> f32 {
    let h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// --- The Main Scene Description ---

fn map(p_in: vec3f) -> vec2f {
    var p = p_in;
    
    let time = uniforms.time ;

    // 1. Ground
    var res = vec2f(p.y + 0.5, MAT_GROUND);

    // 2. Stem
    var p_stem = p;
    p_stem.x = p_stem.x + sin(p_stem.y * 2.0) * 0.1;
    p_stem.z = p_stem.z + cos(p_stem.y * 3.0) * 0.05;
    
    let stemRadius = 0.06  * smoothstep(2.5, 0.0, p_stem.y) + 0.01;
    let d_stem = sdCappedCylinder(p_stem - vec3f(0.0, 1.0, 0.0), 1.2, stemRadius);
    
    if (d_stem < res.x) { 
        res = vec2f(d_stem, MAT_STEM); 
    }

    // // 3. Leaves
    // // Leaf 1
    // var p_leaf1 = p - vec3f(0.1, 0.3, 0.1); 
    
    // // Manual rotation YZ
    // let rot_leaf1_yz = rot2D(vec2f(p_leaf1.y, p_leaf1.z), 0.8);
    // p_leaf1.y = rot_leaf1_yz.x;
    // p_leaf1.z = rot_leaf1_yz.y;
    
    // // Manual rotation XZ
    // let rot_leaf1_xz = rot2D(vec2f(p_leaf1.x, p_leaf1.z), 0.5);
    // p_leaf1.x = rot_leaf1_xz.x;
    // p_leaf1.z = rot_leaf1_xz.y;

    // let d_leaf1 = sdEllipsoid(p_leaf1, vec3f(0.2, 0.02, 0.1));

    // // Leaf 2
    // var p_leaf2 = p - vec3f(-0.1, 0.8, -0.1);
    
    // // Manual rotation YZ
    // let rot_leaf2_yz = rot2D(vec2f(p_leaf2.y, p_leaf2.z), 1.0);
    // p_leaf2.y = rot_leaf2_yz.x;
    // p_leaf2.z = rot_leaf2_yz.y;

    // // Manual rotation XZ
    // let rot_leaf2_xz = rot2D(vec2f(p_leaf2.x, p_leaf2.z), -2.0);
    // p_leaf2.x = rot_leaf2_xz.x;
    // p_leaf2.z = rot_leaf2_xz.y;
    
    // let d_leaf2 = sdEllipsoid(p_leaf2, vec3f(0.18, 0.02, 0.09));
    
    // let d_leaves = min(d_leaf1, d_leaf2);
    // res.x = smin(res.x, d_leaves, 0.05);

    // // 4. Rose Head
    // var p_rose = p - vec3f(0.0, 2.2, 0.0);
    // let r_rose = length(p_rose);
    // let safe_r = max(r_rose, 0.001);
    
    // let theta = atan2(p_rose.z, p_rose.x); 
    // let phi = acos(clamp(p_rose.y / safe_r, -1.0, 1.0)); 

    // var petal_dist = r_rose - 0.35;
    // petal_dist = petal_dist + sin(theta * 5.0 + phi * 3.0) * 0.03 * smoothstep(0.0, 1.0, phi);
    // petal_dist = petal_dist + sin(theta * 13.0) * 0.01 * smoothstep(0.5, 0.0, phi);
    
    // let bud = sdSphere(p_rose - vec3f(0.0, 0.1, 0.0), 0.15);
    
    // let d_rose_final = smin(petal_dist, bud, 0.1);
    // res.x = smin(res.x, d_rose_final, 0.1);
    
    // if (length(p - vec3f(0.0, 2.2, 0.0)) < 0.5) {
    //      res.y = MAT_ROSE;
    // }
    // //  else if (d_leaves < d_stem + 0.1) {
    // //      res.y = MAT_STEM;
    // // }

    return res; 
}

fn calc_normal(p: vec3f) -> vec3f {
    let e = 0.002;
    // We manually construct the vectors to avoid swizzling confusion
    let dx = map(p + vec3f(e, 0.0, 0.0)).x - map(p - vec3f(e, 0.0, 0.0)).x;
    let dy = map(p + vec3f(0.0, e, 0.0)).x - map(p - vec3f(0.0, e, 0.0)).x;
    let dz = map(p + vec3f(0.0, 0.0, e)).x - map(p - vec3f(0.0, 0.0, e)).x;
    
    return normalize(vec3f(dx, dy, dz));
}

fn softshadow(ro: vec3f, rd: vec3f, mint: f32, tmax: f32) -> f32 {
	var res = 1.0;
    var t = mint;
    for(var i=0; i<16; i++) {
		let h = map(ro + rd*t).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) { break; }
    }
    return clamp( res, 0.0, 1.0 );
}



@fragment

fn fs_main(@builtin(position) pos: vec4f) -> @location(0) vec4f {

   

   let resolution = uniforms.resolution;
    let uv = (pos.xy * 2.0 - resolution) / resolution.y;
    let uv_flipped = vec2f(uv.x, -uv.y);

    let ro = vec3f(1.0, 2.5, -2.5); 
    let lookAt = vec3f(1.0, 2, 0.0);
    
    let fwd = normalize(lookAt - ro);
    let right = normalize(cross(vec3f(0.0, 1.0, 0.0), fwd));
    let up = cross(fwd, right);
    let rd = normalize(fwd + right * uv_flipped.x + up * uv_flipped.y);
    
    var t = 0.0;        
    var hit = false;    
    var mat_id = -1.0;

    for(var i = 0; i < 150; i++) { 
        let p = ro + rd * t;
        let res = map(p); 
        let d = res.x;
        mat_id = res.y;

        if (d < 0.001) {    
            hit = true;
            break;
        }
        if (t > 20.0) {    
            break;
        }
        t = t + d * 0.8; 
    }

    var final_color =vec3f(0.0, 0.0, 0.0);     

    if (hit) {
        let p = ro + rd * t;       
        let normal = calc_normal(p); 
        
        let light_pos = vec3f(2.0, 5.0, -3.0);
        let light_dir = normalize(light_pos - p);
        
        let diff = clamp(dot(normal, light_dir), 0.1, 1.0);
        let shadow = softshadow(p + normal * 0.01, light_dir, 0.02, length(light_pos - p));

        var albedo = vec3f(0.0);
        
        if (abs(mat_id - MAT_GROUND) < 0.1) {
            albedo = vec3f(0.2, 0.2, 0.2);  
        } else if (abs(mat_id - MAT_STEM) < 0.1) {
            albedo = vec3f(0.05, 0.3, 0.02);
        } else if (abs(mat_id - MAT_ROSE) < 0.1) {
            let height_factor = smoothstep(2.0, 2.4, p.y);
            albedo = mix(vec3f(0.6, 0.0, 0.05), vec3f(0.9, 0.05, 0.1), height_factor);
        }
        

        
        let ambient = vec3f(0.1) * albedo;
        let diffuse = albedo * diff * vec3f(1.0, 0.95, 0.8);// * shadow; 
        
        final_color = ambient + diffuse;
        final_color = mix(final_color, vec3f(0.0, 0.0, 0.0), 1.0 - exp(-0.01 * t * t));
    }

  //  final_color = pow(final_color, vec3f(1.0/2.2));

    return vec4f(final_color, 1.0);

}