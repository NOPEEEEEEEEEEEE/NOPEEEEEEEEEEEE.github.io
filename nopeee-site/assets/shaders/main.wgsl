struct Uniforms {
  resolution: vec2f,
  time: f32,
  padding: f32, // Padding to align the next vec2 to 16 bytes
  camera: vec2f, // x = yaw, y = pitch
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

fn sdBox(p: vec3f, b: vec3f) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec3f(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0);
}

// --- SDF Primitive Helpers ---
fn opRotateY(p: vec3f, angle: f32) -> vec3f {
    let c = cos(angle);
    let s = sin(angle);
    return vec3f(c * p.x - s * p.z, p.y, s * p.x + c * p.z);
}

// Rotates around the X axis (Pitch - tilting forward/back)
fn opRotateX(p: vec3f, angle: f32) -> vec3f {
    let c = cos(angle);
    let s = sin(angle);
    return vec3f(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}


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

fn opCheapBend(p: vec3f) -> vec3f {
    let k = 10.0; // The amount to bend
    
    let c = cos(k * p.x);
    let s = sin(k * p.x);
    
    // Construct 2x2 Rotation Matrix
    // Note: WGSL matrices are column-major, just like GLSL
    let m = mat2x2f(c, -s, s, c);
    
    // Apply rotation to X and Y, leave Z alone
    // The matrix multiplication (m * p.xy) works natively
    return vec3f(m * p.xy, p.z);
}

fn sdVerticalVesicaSegment(p: vec3f, h_in: f32, w_in: f32) -> f32 {
    // 1. Create mutable local copies of the inputs
    var h = h_in * 0.5;
    var w = w_in * 0.5;

    // 2. Shape constants
    let d = 0.5 * (h * h - w * w) / w;
    
    // 3. Project to 2D
    let q = vec2f(length(p.xz), abs(p.y - h));
    
    // 4. Feature selection
    // GLSL: (condition) ? true : false
    // WGSL: select(false, true, condition) <-- IMPORTANT!
    let condition = (h * q.x < d * (q.y - h));
    
    let t = select(
        vec3f(-d, 0.0, d + w), // The "False" case
        vec3f(0.0, h, 0.0),    // The "True" case
        condition
    );
    
    // 5. Distance
    return length(q - t.xy) - t.z;
}




fn dot2(v: vec3f) -> f32 {
    return dot(v, v);
}

fn udTriangle(p: vec3f, a: vec3f, b: vec3f, c: vec3f) -> f32 {
    let ba = b - a; 
    let pa = p - a;
    let cb = c - b; 
    let pb = p - b;
    let ac = a - c; 
    let pc = p - c;
    
    let nor = cross(ba, ac);

    // Calculate the 3 Barycentric/projection conditions
    let cond_val = sign(dot(cross(ba, nor), pa)) +
                   sign(dot(cross(cb, nor), pb)) +
                   sign(dot(cross(ac, nor), pc));

    // EDGE DISTANCE MATH
    // Calculates distance to the 3 distinct line segments
    let d_edge_a = dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa);
    let d_edge_b = dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb);
    let d_edge_c = dot2(ac * clamp(dot(ac, pc) / dot2(ac), 0.0, 1.0) - pc);
    
    let dist_edge = min(min(d_edge_a, d_edge_b), d_edge_c);

    // FACE DISTANCE MATH
    // Calculates distance to the plane
    let dist_face = dot(nor, pa) * dot(nor, pa) / dot2(nor);

    // SELECT
    // If cond_val < 2.0, we are "outside" the projection, use edge distance.
    // Otherwise, use face distance.
    let result_sq = select(
        dist_face,   // False case (cond >= 2.0) -> Face
        dist_edge,   // True case  (cond < 2.0)  -> Edge
        cond_val < 2.0
    );

    return sqrt(result_sq);
}

fn opPolarRep(p: vec3f, repetitions: f32, offset_radius: f32) -> vec3f {
    let PI = 3.14159265;
    
    let angle_step = 2.0 * PI / repetitions;

    let current_angle = atan2(p.z, p.x);
    let dist = length(p.xz);

  
    let sector = round(current_angle / angle_step);

 
    let new_angle = current_angle - sector * angle_step;

   
    let q_xz = vec2f(
        cos(new_angle) * dist,
        sin(new_angle) * dist
    );
    
   
    return vec3f(q_xz.x - offset_radius, p.y, q_xz.y);
}
fn sdVesica(p: vec2f, r: f32, d: f32) -> f32 {
    let p_abs = abs(p);
    let b = sqrt(r * r - d * d);
    
    let condition = (p_abs.y - b) * d > p_abs.x * b;
    
    let d1 = length(p_abs - vec2f(0.0, b));
    let d2 = length(p_abs - vec2f(-d, 0.0)) - r;
    
    return select(d2, d1, condition);
}
fn smax(a: f32, b: f32, k: f32) -> f32 {
    let h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
    return mix(a, b, h) + k * h * (1.0 - h);
}
fn sdPetal(p: vec3f, s: f32) -> f32 {
    var pos = p;

    // Normalize 's' for blending
    // s is now between 0.2 and 0.35
    let t = smoothstep(0.2, 0.35, s);

    let width_factor = mix(0.3, 1.1, t);

    // --- BENDING ---
    
    // 1. SIDE CUPPING (Spoon shape)
    // Stronger on inside (2.0), weaker on outside (1.0)
    let cup_strength = mix(0.5, 0.3, t);
    let cup_strength_y = mix(0.1, 0.6, t);
  //  pos.z += pos.x * pos.x * cup_strength;
   // pos.z += pos.y * pos.y * cup_strength_y;


   

  let tip_height = max(pos.y - 0.3, 0.0);
    
    // We calculate a curve strength based on height
    // We use a square curve (pow 2.0) for a smooth bend
    let curl_amount = pow(tip_height, 2.0) * 3.0 * t; // Active mainly on outer petals
    
    // A. Curl BACK (Negative Z)
  //  pos.z -= curl_amount;
    
   //pos.y += curl_amount * 1.5;
  //  let tip_height = max(pos.y - 0.4, 0.0);
     
    // We reduced the multiplier from 15.0 to 5.0 to stop the "Huge" explosion
  //  let recurve_amount =   //pow(tip_height, 2.5) * 3.0;// * t;
   // pos.z -= recurve_amount;

  
    // --- SHAPE ---
    let taper_strength = mix(0.3, 0.5, t);
    let taper = 1.0 + taper_strength * pos.y;
    

let pointiness = 1+ max(pos.y - 0.6, 0.0) * 2;

    // Clamp taper to be safe
    let p_x =(pos.x ) / (clamp(taper, 0.1, 2.0)* width_factor);// 
    
    // Base Circle
    let d_2d = length(vec2f(p_x, pos.y)) - 0.8; 

    // Cut Top
    let d_flat_top = smax(d_2d, pos.y - 0.35, 0.05);

    // Thickness
    // Scale distance by 0.6 to avoid artifacts
    let d_final_2d = d_flat_top * 0.6; 

    let thickness = 0.01; 
    let d_z = abs(pos.z) - thickness;

    let w = vec2f(d_2d, d_z);
    return min(max(w.x, w.y), 0.0) + length(max(w, vec2f(0.0)));


 
}



fn sdRose(p: vec3f) -> f32 {


    let d_sphere = length(p - vec3f(0.0, 0.1, 0.0)) - 0.5;

    if (d_sphere > 0.05) {
        return d_sphere;
    }

    var d_min = 100.0;
    
    let petal_count =11.0; 
    let golden_angle = 2.39996; 
    
    for (var i = 1.0; i < petal_count; i += 1.0) {
        
        let r = 0.07 * sqrt(i); // Kept radius compact
        let theta = i * golden_angle;
        
        // Lower outer petals
        let petal_center = vec3f(r * cos(theta), -r * 0.2, r * sin(theta));

        // --- FIX 1: REDUCED SCALE RANGE ---
        // Was: 0.2 + ... * 0.3 (Result 0.5)
        // Now: 0.2 + ... * 0.15 (Result 0.35)
        // This prevents the outer petals from becoming giant monsters.
        let scale = 0.1 + (i / petal_count) * 0.25;

        var q = p - petal_center;
        
        q = opRotateY(q, -theta + 1.57);
        
        // --- FIX 2: TILT ADJUSTMENT ---
        // Inner: -0.2 (Tucked in)
        // Outer: 0.6 (Opened up, but not falling over)
        let tilt = -0.2 + (i / petal_count) * 0.8; 
     //   q = opRotateX(q, -tilt);
        
        // Scale the coordinate space
        q = q / 0.2;

        // Calculate distance and multiply back
        let d = sdPetal(q, scale) * scale;
        
        d_min = min(d_min, d);
    }
    
    return d_min;
}



fn flower(p: vec3f, location: vec3f) -> f32 {
    let center = vec3f(0.0, 0.0, 0.0);
    let pos = p - (center + location);

    var q = opPolarRep(pos, 5.0, 0.1);

    let curve = q.x * q.x*2 ; 
    
   
    let wave = sin(q.x * 50.0) * 0.005 + sin(q.z * 50.0) * 0.005 +sin(q.x * 80.0) * 0.003 + sin(q.z * 80.0) * 0.003 ;
    

    q.y += curve + wave; 

    
    let size = 0.2;
    let v1 = vec3f(0.0, 0.0, -1.0 * size * 0.5);
    let v2 = vec3f(0.0, 0.0,  1.0 * size * 0.5); 
    let v3 = vec3f(2.0 * size, 0.0, 0.0);       

   
    let d_flat = udTriangle(q, v1, v2, v3);
    let d_sepals = d_flat - 0.01; 

   

    let d_bud = sdVerticalVesicaSegment(pos - vec3f(0.0, -0.2, 0.0), 0.4, 0.20);



  //  let d = sdPetal(pos ,1);

 
   
   
    // Combine with floor
   let flower =  sdRose(pos); //min(d, min(d_sepals, d_bud));

   return flower;
}

// --- The Main Scene Description ---

fn map(p_in: vec3f) -> vec2f {
    var p = p_in;
    
    let time = uniforms.time ;

    // 1. Ground
     var res = vec2f(p.y + 0.5, MAT_GROUND);

    let flower_pos = vec3f(0.0, 2.0, 0.0);

    let d_t =  flower(p, flower_pos);

    if (d_t < res.x) { 
        res = vec2f(d_t, MAT_STEM); 
    }

    // // 2. Stem
    var p_stem = p;
    p_stem.x = p_stem.x + sin(p_stem.y * 2.0) * 0.1;
    p_stem.z = p_stem.z + cos(p_stem.y * 3.0) * 0.05;
    
    let stemRadius = 0.06  * smoothstep(2.5, 0.0, p_stem.y) + 0.01;
    let d_stem = sdCappedCylinder(p_stem - vec3f(0.0, 1.0, 0.0), 1.2, stemRadius);
    
    // if (d_stem < res.x) { 
    //     res = vec2f(d_stem, MAT_STEM); 
    // }

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

    let time = uniforms.time * 2.0 ;

    let yaw = uniforms.camera.x;
    let pitch = uniforms.camera.y;
let radius = 1.0;
   let ro = vec3f(
        radius * cos(pitch) * sin(yaw),
        radius * sin(pitch) + 2.0, // +2.0 to keep height relative to lookAt
        radius * cos(pitch) * cos(yaw)
    ) + vec3f(0.0, 0.0, 0.0);

    let lookAt = vec3f(0.0, 2, 0.0);
    
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
        t = t + d * 0.3; 
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
            albedo = vec3f(0.05, 0.15, 0.02);
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