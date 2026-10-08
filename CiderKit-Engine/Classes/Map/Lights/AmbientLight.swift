public class AmbientLight: BaseLightImplementation<AmbientLightDescription> {

    public override func match(description: AmbientLightDescription) {
        self.description = description
    }

}
